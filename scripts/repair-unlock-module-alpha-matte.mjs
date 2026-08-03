import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const mediaDirectory = path.resolve('entry/src/main/resources/base/media');
const shouldWrite = process.argv.includes('--write');
const shouldPreview = process.argv.includes('--preview');
const shouldVerify = process.argv.includes('--verify');
const previewDirectory = '/private/tmp/harmony-unlock-module-alpha-preview';
const modulePaths = Array.from(
  { length: 11 },
  (_, index) => path.join(mediaDirectory, `module${index + 1}.png`)
);

const pngSignature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

function paethPredictor(left, up, upperLeft) {
  const estimate = left + up - upperLeft;
  const leftDistance = Math.abs(estimate - left);
  const upDistance = Math.abs(estimate - up);
  const upperLeftDistance = Math.abs(estimate - upperLeft);
  if (leftDistance <= upDistance && leftDistance <= upperLeftDistance) {
    return left;
  }
  return upDistance <= upperLeftDistance ? up : upperLeft;
}

function decodeRgbaPng(pngBytes) {
  if (!pngBytes.subarray(0, pngSignature.length).equals(pngSignature)) {
    throw new Error('Invalid PNG signature');
  }

  let width = 0;
  let height = 0;
  const idatChunks = [];
  let offset = pngSignature.length;
  while (offset < pngBytes.length) {
    const length = pngBytes.readUInt32BE(offset);
    const type = pngBytes.toString('ascii', offset + 4, offset + 8);
    const data = pngBytes.subarray(offset + 8, offset + 8 + length);
    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
      if (data[8] !== 8 || data[9] !== 6 || data[12] !== 0) {
        throw new Error('Only non-interlaced 8-bit RGBA PNG files are supported');
      }
    } else if (type === 'IDAT') {
      idatChunks.push(data);
    } else if (type === 'IEND') {
      break;
    }
    offset += length + 12;
  }

  const bytesPerPixel = 4;
  const rowStride = width * bytesPerPixel;
  const filtered = zlib.inflateSync(Buffer.concat(idatChunks));
  const rgba = Buffer.alloc(width * height * bytesPerPixel);
  for (let y = 0; y < height; y += 1) {
    const filteredRowOffset = y * (rowStride + 1);
    const filterType = filtered[filteredRowOffset];
    const rowOffset = y * rowStride;
    const previousRowOffset = (y - 1) * rowStride;
    for (let x = 0; x < rowStride; x += 1) {
      const source = filtered[filteredRowOffset + 1 + x];
      const left = x >= bytesPerPixel ? rgba[rowOffset + x - bytesPerPixel] : 0;
      const up = y > 0 ? rgba[previousRowOffset + x] : 0;
      const upperLeft = y > 0 && x >= bytesPerPixel
        ? rgba[previousRowOffset + x - bytesPerPixel]
        : 0;
      let prediction = 0;
      if (filterType === 1) {
        prediction = left;
      } else if (filterType === 2) {
        prediction = up;
      } else if (filterType === 3) {
        prediction = Math.floor((left + up) / 2);
      } else if (filterType === 4) {
        prediction = paethPredictor(left, up, upperLeft);
      } else if (filterType !== 0) {
        throw new Error(`Unsupported PNG filter ${filterType}`);
      }
      rgba[rowOffset + x] = (source + prediction) & 0xff;
    }
  }
  return { width, height, rgba };
}

const crcTable = new Uint32Array(256);
for (let index = 0; index < crcTable.length; index += 1) {
  let value = index;
  for (let bit = 0; bit < 8; bit += 1) {
    value = value & 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
  }
  crcTable[index] = value >>> 0;
}

function crc32(bytes) {
  let value = 0xffffffff;
  for (const byte of bytes) {
    value = crcTable[(value ^ byte) & 0xff] ^ (value >>> 8);
  }
  return (value ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const typeBytes = Buffer.from(type, 'ascii');
  const lengthBytes = Buffer.alloc(4);
  lengthBytes.writeUInt32BE(data.length, 0);
  const crcBytes = Buffer.alloc(4);
  crcBytes.writeUInt32BE(crc32(Buffer.concat([typeBytes, data])), 0);
  return Buffer.concat([lengthBytes, typeBytes, data, crcBytes]);
}

function encodeRgbaPng(width, height, rgba) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  const rowStride = width * 4;
  const filtered = Buffer.alloc((rowStride + 1) * height);
  for (let y = 0; y < height; y += 1) {
    const filteredRowOffset = y * (rowStride + 1);
    filtered[filteredRowOffset] = 0;
    rgba.copy(filtered, filteredRowOffset + 1, y * rowStride, (y + 1) * rowStride);
  }
  return Buffer.concat([
    pngSignature,
    pngChunk('IHDR', ihdr),
    pngChunk('IDAT', zlib.deflateSync(filtered, { level: 9 })),
    pngChunk('IEND', Buffer.alloc(0)),
  ]);
}

function pixelOffset(pixelIndex) {
  return pixelIndex * 4;
}

function countDarkLowAlphaPixels(rgba) {
  let count = 0;
  for (let offset = 0; offset < rgba.length; offset += 4) {
    const alpha = rgba[offset + 3];
    if (
      alpha > 0 && alpha <= 32 &&
      rgba[offset] < 24 && rgba[offset + 1] < 24 && rgba[offset + 2] < 24
    ) {
      count += 1;
    }
  }
  return count;
}

function repairLowAlphaMatte(rgba, width, height) {
  const repaired = Buffer.from(rgba);
  const pixelCount = width * height;
  const queue = new Int32Array(pixelCount);
  const depth = new Uint8Array(pixelCount);
  const filled = new Uint8Array(pixelCount);
  let removedShadowPixels = 0;
  let unpremultipliedEdgePixels = 0;

  for (let offset = 0; offset < repaired.length; offset += 4) {
    const alpha = repaired[offset + 3];
    if (alpha === 0 || alpha > 32) {
      continue;
    }
    repaired[offset] = Math.min(255, Math.round((repaired[offset] * 255) / alpha));
    repaired[offset + 1] = Math.min(255, Math.round((repaired[offset + 1] * 255) / alpha));
    repaired[offset + 2] = Math.min(255, Math.round((repaired[offset + 2] * 255) / alpha));
    unpremultipliedEdgePixels += 1;
    if (repaired[offset] < 24 && repaired[offset + 1] < 24 && repaired[offset + 2] < 24) {
      repaired[offset + 3] = 0;
      removedShadowPixels += 1;
    }
  }

  let tail = 0;

  for (let pixelIndex = 0; pixelIndex < pixelCount; pixelIndex += 1) {
    const offset = pixelOffset(pixelIndex);
    if (repaired[offset + 3] > 0) {
      filled[pixelIndex] = 1;
      queue[tail] = pixelIndex;
      tail += 1;
    }
  }

  let changedPixels = 0;
  let head = 0;
  while (head < tail) {
    const sourceIndex = queue[head];
    head += 1;
    const sourceDepth = depth[sourceIndex];
    const sourceOffset = pixelOffset(sourceIndex);
    const x = sourceIndex % width;
    const y = Math.floor(sourceIndex / width);
    const neighbors = [
      x > 0 ? sourceIndex - 1 : -1,
      x + 1 < width ? sourceIndex + 1 : -1,
      y > 0 ? sourceIndex - width : -1,
      y + 1 < height ? sourceIndex + width : -1,
    ];

    for (const neighborIndex of neighbors) {
      if (neighborIndex < 0 || filled[neighborIndex]) {
        continue;
      }
      const targetOffset = pixelOffset(neighborIndex);
      const targetAlpha = repaired[targetOffset + 3];
      if (targetAlpha > 0 || sourceDepth >= 4) {
        continue;
      }
      repaired[targetOffset] = repaired[sourceOffset];
      repaired[targetOffset + 1] = repaired[sourceOffset + 1];
      repaired[targetOffset + 2] = repaired[sourceOffset + 2];
      filled[neighborIndex] = 1;
      depth[neighborIndex] = sourceDepth + 1;
      queue[tail] = neighborIndex;
      tail += 1;
      changedPixels += 1;
    }
  }
  return {
    repaired,
    changedPixels,
    removedShadowPixels,
    unpremultipliedEdgePixels,
  };
}

const report = [];
for (const modulePath of modulePaths) {
  const decoded = decodeRgbaPng(fs.readFileSync(modulePath));
  const before = countDarkLowAlphaPixels(decoded.rgba);
  const result = repairLowAlphaMatte(decoded.rgba, decoded.width, decoded.height);
  const after = countDarkLowAlphaPixels(result.repaired);
  const encoded = shouldWrite || shouldPreview
    ? encodeRgbaPng(decoded.width, decoded.height, result.repaired)
    : undefined;
  if (shouldWrite && encoded !== undefined) {
    fs.writeFileSync(
      modulePath,
      encoded
    );
  }
  if (shouldPreview && encoded !== undefined) {
    fs.mkdirSync(previewDirectory, { recursive: true });
    fs.writeFileSync(path.join(previewDirectory, path.basename(modulePath)), encoded);
  }
  report.push({
    module: path.basename(modulePath),
    before,
    after,
    changedPixels: result.changedPixels,
    removedShadowPixels: result.removedShadowPixels,
    unpremultipliedEdgePixels: result.unpremultipliedEdgePixels,
  });
}

if (shouldVerify && report.some((item) => item.before !== 0)) {
  throw new Error('Unlock module assets still contain low-alpha black matte pixels');
}

const mode = shouldWrite ? 'write' : shouldPreview ? 'preview' : shouldVerify ? 'verify' : 'check';
console.log(JSON.stringify({ mode, modules: report }, null, 2));
