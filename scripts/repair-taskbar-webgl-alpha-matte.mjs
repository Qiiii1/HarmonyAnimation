import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const rawfileHtmlPath = path.resolve('entry/src/main/resources/rawfile/taskbar_up_webgl.html');
const foregroundPngPath = path.resolve('entry/src/main/resources/rawfile/taskbar_up_webgl_background3.png');

const rawTextureMarker = 'window.TASKBAR_UP_WEBGL_RAW_TEXTURES = ';
const html = fs.readFileSync(rawfileHtmlPath, 'utf8');
const rawTextureStart = html.indexOf(rawTextureMarker) + rawTextureMarker.length;
const rawTextureEnd = html.indexOf(';\n</script>', rawTextureStart);

if (rawTextureStart < rawTextureMarker.length || rawTextureEnd <= rawTextureStart) {
  throw new Error('Could not find inline WebGL raw texture payload');
}

const rawTextures = JSON.parse(html.slice(rawTextureStart, rawTextureEnd));

function getPixelOffset(pixelIndex) {
  return pixelIndex * 4;
}

function unpremultiply(bytes) {
  for (let offset = 0; offset < bytes.length; offset += 4) {
    const alpha = bytes[offset + 3];
    if (alpha > 0 && alpha < 255) {
      bytes[offset] = Math.min(255, Math.round((bytes[offset] * 255) / alpha));
      bytes[offset + 1] = Math.min(255, Math.round((bytes[offset + 1] * 255) / alpha));
      bytes[offset + 2] = Math.min(255, Math.round((bytes[offset + 2] * 255) / alpha));
    }
  }
}

function bleedTransparentRgb(bytes, width, height) {
  const pixelCount = width * height;
  const queue = new Int32Array(pixelCount);
  const filled = new Uint8Array(pixelCount);
  let tail = 0;

  for (let pixelIndex = 0; pixelIndex < pixelCount; pixelIndex += 1) {
    const offset = getPixelOffset(pixelIndex);
    if (bytes[offset + 3] > 32) {
      filled[pixelIndex] = 1;
      queue[tail] = pixelIndex;
      tail += 1;
    }
  }

  if (tail === 0) {
    return;
  }

  let head = 0;
  while (head < tail) {
    const pixelIndex = queue[head];
    head += 1;

    const x = pixelIndex % width;
    const y = Math.floor(pixelIndex / width);
    const sourceOffset = getPixelOffset(pixelIndex);
    const neighbors = [
      x > 0 ? pixelIndex - 1 : -1,
      x + 1 < width ? pixelIndex + 1 : -1,
      y > 0 ? pixelIndex - width : -1,
      y + 1 < height ? pixelIndex + width : -1,
    ];

    for (const neighbor of neighbors) {
      if (neighbor < 0 || filled[neighbor]) {
        continue;
      }

      const targetOffset = getPixelOffset(neighbor);
      bytes[targetOffset] = bytes[sourceOffset];
      bytes[targetOffset + 1] = bytes[sourceOffset + 1];
      bytes[targetOffset + 2] = bytes[sourceOffset + 2];
      filled[neighbor] = 1;
      queue[tail] = neighbor;
      tail += 1;
    }
  }

  for (let offset = 0; offset < bytes.length; offset += 4) {
    const alpha = bytes[offset + 3];
    if (alpha > 0 && alpha <= 32 && bytes[offset] < 8 && bytes[offset + 1] < 8 && bytes[offset + 2] < 8) {
      bytes[offset] = 32;
      bytes[offset + 1] = 32;
      bytes[offset + 2] = 32;
    }
  }
}

function countDarkTransparentPixels(bytes) {
  let count = 0;
  for (let offset = 0; offset < bytes.length; offset += 4) {
    const alpha = bytes[offset + 3];
    if (alpha > 0 && alpha <= 32 && bytes[offset] < 8 && bytes[offset + 1] < 8 && bytes[offset + 2] < 8) {
      count += 1;
    }
  }
  return count;
}

function repairTexture(texture) {
  const width = Math.max(1, Number(texture.width) || 1);
  const height = Math.max(1, Number(texture.height) || 1);
  const bytes = Buffer.from(texture.rgba, 'base64');
  if (bytes.length !== width * height * 4) {
    throw new Error(`Unexpected RGBA byte length for ${width}x${height}: ${bytes.length}`);
  }

  const before = countDarkTransparentPixels(bytes);
  unpremultiply(bytes);
  bleedTransparentRgb(bytes, width, height);
  const after = countDarkTransparentPixels(bytes);

  return {
    texture: {
      ...texture,
      rgba: bytes.toString('base64'),
    },
    bytes,
    before,
    after,
  };
}

const crcTable = new Uint32Array(256);
for (let n = 0; n < 256; n += 1) {
  let c = n;
  for (let k = 0; k < 8; k += 1) {
    c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  }
  crcTable[n] = c >>> 0;
}

function crc32(buffer) {
  let c = 0xffffffff;
  for (const byte of buffer) {
    c = crcTable[(c ^ byte) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const typeBuffer = Buffer.from(type, 'ascii');
  const lengthBuffer = Buffer.alloc(4);
  lengthBuffer.writeUInt32BE(data.length, 0);
  const crcBuffer = Buffer.alloc(4);
  crcBuffer.writeUInt32BE(crc32(Buffer.concat([typeBuffer, data])), 0);
  return Buffer.concat([lengthBuffer, typeBuffer, data, crcBuffer]);
}

function encodePng(width, height, rgbaBytes) {
  const header = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  const scanlineStride = width * 4;
  const filtered = Buffer.alloc((scanlineStride + 1) * height);
  for (let y = 0; y < height; y += 1) {
    const filteredOffset = y * (scanlineStride + 1);
    filtered[filteredOffset] = 0;
    rgbaBytes.copy(filtered, filteredOffset + 1, y * scanlineStride, (y + 1) * scanlineStride);
  }

  return Buffer.concat([
    header,
    pngChunk('IHDR', ihdr),
    pngChunk('IDAT', zlib.deflateSync(filtered, { level: 9 })),
    pngChunk('IEND', Buffer.alloc(0)),
  ]);
}

const foregroundResult = repairTexture(rawTextures.background3);
const softForegroundResult = repairTexture(rawTextures.background3Soft);
rawTextures.background3 = foregroundResult.texture;
rawTextures.background3Soft = softForegroundResult.texture;

fs.writeFileSync(
  rawfileHtmlPath,
  html.slice(0, rawTextureStart) + JSON.stringify(rawTextures) + html.slice(rawTextureEnd)
);
fs.writeFileSync(
  foregroundPngPath,
  encodePng(rawTextures.background3.width, rawTextures.background3.height, foregroundResult.bytes)
);

console.log(JSON.stringify({
  background3: { before: foregroundResult.before, after: foregroundResult.after },
  background3Soft: { before: softForegroundResult.before, after: softForegroundResult.after },
}, null, 2));
