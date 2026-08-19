import CoreGraphics
import Foundation
import ImageIO

struct AssetSpec {
  let source: String
  let output: String
  let width: Int
  let height: Int
}

struct RawAsset: Encodable {
  let width: Int
  let height: Int
  let rgba: String
}

struct RawTexturePayload: Encodable {
  let background2: RawAsset
  let background2Soft: RawAsset
  let background3: RawAsset
  let background3Soft: RawAsset
  let cards: [RawAsset]
  let icons: [RawAsset]
}

let rawfileHtmlPath = "entry/src/main/resources/rawfile/taskbar_up_webgl.html"
let rawTextureMarker = "window.TASKBAR_UP_WEBGL_RAW_TEXTURES = "
let rawTextureEndMarker = ";\n</script>"

let sharpBackgroundWidth = 836
let sharpBackgroundHeight = 1812
let blurLayerWidth = 418
let blurLayerHeight = 906
let cardWidth = 501
let cardHeight = 1080
let iconSize = 96

let background2Spec = AssetSpec(
  source: "entry/src/main/resources/base/media/Background5.png",
  output: "entry/src/main/resources/rawfile/taskbar_up_webgl_background5.png",
  width: sharpBackgroundWidth,
  height: sharpBackgroundHeight
)
let background2SoftSpec = AssetSpec(
  source: "entry/src/main/resources/base/media/BlurBackground.png",
  output: "entry/src/main/resources/rawfile/taskbar_up_webgl_blur_background.png",
  width: blurLayerWidth,
  height: blurLayerHeight
)
let background3Spec = AssetSpec(
  source: "entry/src/main/resources/base/media/Background3.png",
  output: "entry/src/main/resources/rawfile/taskbar_up_webgl_background3.png",
  width: sharpBackgroundWidth,
  height: sharpBackgroundHeight
)
let background3SoftSpec = AssetSpec(
  source: "entry/src/main/resources/base/media/BlurIcon.png",
  output: "entry/src/main/resources/rawfile/taskbar_up_webgl_blur_icon.png",
  width: blurLayerWidth,
  height: blurLayerHeight
)

let cardSpecs = [
  AssetSpec(source: "entry/src/main/resources/base/media/Card1.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card1.png", width: cardWidth, height: cardHeight),
  AssetSpec(source: "entry/src/main/resources/base/media/Card2.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card2.png", width: cardWidth, height: cardHeight),
  AssetSpec(source: "entry/src/main/resources/base/media/Card3.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card3.png", width: cardWidth, height: cardHeight),
  AssetSpec(source: "entry/src/main/resources/base/media/Card4.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card4.png", width: cardWidth, height: cardHeight),
  AssetSpec(source: "entry/src/main/resources/base/media/card5.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card5.png", width: cardWidth, height: cardHeight),
  AssetSpec(source: "entry/src/main/resources/base/media/card6.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_card6.png", width: cardWidth, height: cardHeight),
]

let iconSpecs = [
  AssetSpec(source: "entry/src/main/resources/base/media/icon1.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon1.png", width: iconSize, height: iconSize),
  AssetSpec(source: "entry/src/main/resources/base/media/icon2.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon2.png", width: iconSize, height: iconSize),
  AssetSpec(source: "entry/src/main/resources/base/media/icon3.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon3.png", width: iconSize, height: iconSize),
  AssetSpec(source: "entry/src/main/resources/base/media/icon4.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon4.png", width: iconSize, height: iconSize),
  AssetSpec(source: "entry/src/main/resources/base/media/icon5.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon5.png", width: iconSize, height: iconSize),
  AssetSpec(source: "entry/src/main/resources/base/media/icon6.png", output: "entry/src/main/resources/rawfile/taskbar_up_webgl_icon6.png", width: iconSize, height: iconSize),
]

func projectURL(_ path: String) -> URL {
  URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(path)
}

func loadImage(_ path: String) throws -> CGImage {
  let url = projectURL(path)
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
    if bytes[offset(pixelIndex) + 3] > 32 {
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

  for pixelIndex in 0..<pixelCount {
    let pixelOffset = offset(pixelIndex)
    let alpha = bytes[pixelOffset + 3]
    if alpha > 0 &&
      alpha <= 32 &&
      bytes[pixelOffset] < 8 &&
      bytes[pixelOffset + 1] < 8 &&
      bytes[pixelOffset + 2] < 8 {
      bytes[pixelOffset] = 32
      bytes[pixelOffset + 1] = 32
      bytes[pixelOffset + 2] = 32
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

  let url = projectURL(path)
  guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    throw NSError(domain: "AssetGeneration", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to create PNG destination \(path)"])
  }
  CGImageDestinationAddImage(destination, image, nil)
  if !CGImageDestinationFinalize(destination) {
    throw NSError(domain: "AssetGeneration", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to write \(path)"])
  }
}

func makeRawAsset(_ spec: AssetSpec) throws -> RawAsset {
  let image = try loadImage(spec.source)
  let bytes = try renderAsset(image, width: spec.width, height: spec.height)
  try writePng(bytes, width: spec.width, height: spec.height, path: spec.output)
  return RawAsset(width: spec.width, height: spec.height, rgba: Data(bytes).base64EncodedString())
}

func injectRawTextures(_ payload: RawTexturePayload) throws {
  let htmlURL = projectURL(rawfileHtmlPath)
  let html = try String(contentsOf: htmlURL, encoding: .utf8)
  guard let markerRange = html.range(of: rawTextureMarker),
        let endRange = html.range(of: rawTextureEndMarker, range: markerRange.upperBound..<html.endIndex) else {
    throw NSError(domain: "AssetGeneration", code: 6, userInfo: [NSLocalizedDescriptionKey: "Unable to find inline WebGL raw texture payload"])
  }

  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys]
  let payloadData = try encoder.encode(payload)
  guard let payloadJson = String(data: payloadData, encoding: .utf8) else {
    throw NSError(domain: "AssetGeneration", code: 7, userInfo: [NSLocalizedDescriptionKey: "Unable to encode raw texture payload"])
  }

  let prefix = String(html[..<markerRange.upperBound])
  let suffix = String(html[endRange.lowerBound...])
  let updatedHtml = prefix + payloadJson + suffix
  try String(updatedHtml).write(to: htmlURL, atomically: true, encoding: .utf8)
}

let payload = RawTexturePayload(
  background2: try makeRawAsset(background2Spec),
  background2Soft: try makeRawAsset(background2SoftSpec),
  background3: try makeRawAsset(background3Spec),
  background3Soft: try makeRawAsset(background3SoftSpec),
  cards: try cardSpecs.map { try makeRawAsset($0) },
  icons: try iconSpecs.map { try makeRawAsset($0) }
)

try injectRawTextures(payload)

let summary: [String: Any] = [
  "background2": ["width": payload.background2.width, "height": payload.background2.height],
  "background2Soft": ["width": payload.background2Soft.width, "height": payload.background2Soft.height],
  "background3": ["width": payload.background3.width, "height": payload.background3.height],
  "background3Soft": ["width": payload.background3Soft.width, "height": payload.background3Soft.height],
  "cards": payload.cards.map { ["width": $0.width, "height": $0.height] },
  "icons": payload.icons.map { ["width": $0.width, "height": $0.height] },
]
let summaryData = try JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys])
try summaryData.write(to: URL(fileURLWithPath: "/private/tmp/taskbar-webgl-assets-summary.json"))
print("Generated and injected taskbar WebGL assets")
