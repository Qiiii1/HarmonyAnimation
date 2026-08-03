import CoreGraphics
import Foundation
import ImageIO

struct AssetSpec {
  let source: String
  let output: String
  let rawKey: String
  let width: Int
  let height: Int
}

struct RawAsset: Encodable {
  let width: Int
  let height: Int
  let rgba: String
}

let specs = [
  AssetSpec(
    source: "entry/src/main/resources/base/media/card5.png",
    output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card5.png",
    rawKey: "card5",
    width: 334,
    height: 720
  ),
  AssetSpec(
    source: "entry/src/main/resources/base/media/card6.png",
    output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card6.png",
    rawKey: "card6",
    width: 334,
    height: 720
  ),
  AssetSpec(
    source: "entry/src/main/resources/base/media/icon5.png",
    output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon5.png",
    rawKey: "icon5",
    width: 96,
    height: 96
  ),
  AssetSpec(
    source: "entry/src/main/resources/base/media/icon6.png",
    output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon6.png",
    rawKey: "icon6",
    width: 96,
    height: 96
  ),
]

func loadImage(_ path: String) throws -> CGImage {
  let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(path)
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    throw NSError(domain: "AssetGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to load \(path)"])
  }
  return image
}

func offset(_ pixelIndex: Int) -> Int {
  pixelIndex * 4
}

func unpremultiply(_ bytes: inout [UInt8]) {
  var byteOffset = 0
  while byteOffset < bytes.count {
    let alpha = Int(bytes[byteOffset + 3])
    if alpha > 0 && alpha < 255 {
      bytes[byteOffset] = UInt8(min(255, (Int(bytes[byteOffset]) * 255 + alpha / 2) / alpha))
      bytes[byteOffset + 1] = UInt8(min(255, (Int(bytes[byteOffset + 1]) * 255 + alpha / 2) / alpha))
      bytes[byteOffset + 2] = UInt8(min(255, (Int(bytes[byteOffset + 2]) * 255 + alpha / 2) / alpha))
    }
    byteOffset += 4
  }
}

func bleedTransparentRgb(_ bytes: inout [UInt8], width: Int, height: Int) {
  let pixelCount = width * height
  var queue = Array(repeating: 0, count: pixelCount)
  var filled = Array(repeating: false, count: pixelCount)
  var tail = 0

  for pixelIndex in 0..<pixelCount {
    if bytes[offset(pixelIndex) + 3] > 24 {
      filled[pixelIndex] = true
      queue[tail] = pixelIndex
      tail += 1
    }
  }

  if tail == 0 {
    return
  }

  var head = 0
  while head < tail {
    let pixelIndex = queue[head]
    head += 1

    let x = pixelIndex % width
    let y = pixelIndex / width
    let sourceOffset = offset(pixelIndex)
    let neighbors = [
      x > 0 ? pixelIndex - 1 : -1,
      x + 1 < width ? pixelIndex + 1 : -1,
      y > 0 ? pixelIndex - width : -1,
      y + 1 < height ? pixelIndex + width : -1,
    ]

    for neighbor in neighbors {
      if neighbor < 0 || filled[neighbor] {
        continue
      }
      let targetOffset = offset(neighbor)
      bytes[targetOffset] = bytes[sourceOffset]
      bytes[targetOffset + 1] = bytes[sourceOffset + 1]
      bytes[targetOffset + 2] = bytes[sourceOffset + 2]
      filled[neighbor] = true
      queue[tail] = neighbor
      tail += 1
    }
  }
}

func renderAsset(_ image: CGImage, width: Int, height: Int) throws -> [UInt8] {
  var bytes = Array(repeating: UInt8(0), count: width * height * 4)
  let colorSpace = CGColorSpaceCreateDeviceRGB()
  let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
  guard let context = CGContext(
    data: &bytes,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: colorSpace,
    bitmapInfo: bitmapInfo
  ) else {
    throw NSError(domain: "AssetGeneration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
  }

  context.clear(CGRect(x: 0, y: 0, width: width, height: height))
  context.interpolationQuality = .high
  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

  unpremultiply(&bytes)
  bleedTransparentRgb(&bytes, width: width, height: height)
  return bytes
}

func writePng(_ bytes: [UInt8], width: Int, height: Int, path: String) throws {
  let data = Data(bytes)
  guard let provider = CGDataProvider(data: data as CFData),
        let image = CGImage(
          width: width,
          height: height,
          bitsPerComponent: 8,
          bitsPerPixel: 32,
          bytesPerRow: width * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.last.rawValue),
          provider: provider,
          decode: nil,
          shouldInterpolate: true,
          intent: .defaultIntent
        ) else {
    throw NSError(domain: "AssetGeneration", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create PNG image"])
  }

  let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(path)
  guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    throw NSError(domain: "AssetGeneration", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to create PNG destination \(path)"])
  }
  CGImageDestinationAddImage(destination, image, nil)
  if !CGImageDestinationFinalize(destination) {
    throw NSError(domain: "AssetGeneration", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to write \(path)"])
  }
}

var output: [String: RawAsset] = [:]

for spec in specs {
  let image = try loadImage(spec.source)
  let bytes = try renderAsset(image, width: spec.width, height: spec.height)
  try writePng(bytes, width: spec.width, height: spec.height, path: spec.output)
  output[spec.rawKey] = RawAsset(width: spec.width, height: spec.height, rgba: Data(bytes).base64EncodedString())
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
let data = try encoder.encode(output)
try data.write(to: URL(fileURLWithPath: "/private/tmp/taskbar-webgl-new-assets.json"))
print("Generated \(output.count) taskbar WebGL assets")
