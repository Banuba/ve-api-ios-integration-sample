//
//  ExportEffectProvider.swift
//  VEAPISample
//
//  Created by Andrei Sak on 19.12.22.
//

import VEEffectsSDK
import UIKit

enum ExportEffectType {
  case color
  case visual
  case speed
  case overlay
  case mask
}

struct ExportEffect {
  let type: ExportEffectType
  let id: UInt
  let startTime: CMTime
  let endTime: CMTime
  let additionalInfo: [String: Any]
}

struct ExportEffectAdditionalInfoKey {
  static let url: String = "url"
  static let name: String = "name"
  static let effectInfo: String = "effectInfo"
}

class ExportEffectProvider {
  /// Unique effect id
  var uniqueEffectId: UInt {
    UInt.random(in: 0...100)
  }
  
  private var totalVideoDuration: CMTime = .zero
  
  init(totalVideoDuration: CMTime) {
    self.totalVideoDuration = totalVideoDuration
  }
  
  func provideExportEffects() -> [ExportEffect] {
    return [
      provideMaskExportEffect(),
      provideColorExportEffect(),
      provideVisualExportEffect(type: .vhs),
      provideSpeedExportEffect(type: .slowmo),
      provideOverlayExportEffect(type: .gif),
      provideOverlayExportEffect(type: .text)
    ]
  }
  
  func provideMaskExportEffect() -> ExportEffect {
    let maskName = "AsaiLines"
    let url = Bundle.main.bundlePath + "/effects/" + maskName
    var isDirectory = ObjCBool(true)
    guard FileManager.default.fileExists(atPath: url, isDirectory: &isDirectory) else {
      fatalError("Unable to find mask at specified url")
    }
    
    return ExportEffect(
      type: .mask,
      id: EffectIDs.maskEffectStartId + uniqueEffectId,
      startTime: .zero,
      endTime: totalVideoDuration,
      additionalInfo: [
        ExportEffectAdditionalInfoKey.url: url,
        ExportEffectAdditionalInfoKey.name: maskName
      ]
    )
  }
  
  func provideColorExportEffect() -> ExportEffect {
    guard let url = Bundle.main.url(forResource: "luts/japan", withExtension: "png") else {
      fatalError("Unable to find color filter at specified url")
    }
    
    return ExportEffect(
      type: .color,
      id: EffectIDs.colorEffectStartId + uniqueEffectId,
      startTime: .zero,
      endTime: totalVideoDuration,
      additionalInfo: [
        ExportEffectAdditionalInfoKey.url: url,
        ExportEffectAdditionalInfoKey.name: "Japan"
      ]
    )
  }
  
  func provideVisualExportEffect(type: VisualEffectApplicatorType) -> ExportEffect {
    return ExportEffect(
      type: .visual,
      id: EffectIDs.visualEffectStartId + uniqueEffectId,
      startTime: .zero,
      endTime: totalVideoDuration,
      additionalInfo: [ExportEffectAdditionalInfoKey.name: type]
    )
  }
  
  func provideSpeedExportEffect(type: SpeedEffectType) -> ExportEffect {
    return ExportEffect(
      type: .speed,
      id: EffectIDs.speedEffectStartId + uniqueEffectId,
      startTime: .zero,
      endTime: totalVideoDuration,
      additionalInfo: [ExportEffectAdditionalInfoKey.name: type]
    )
  }
  
  func provideOverlayExportEffect(type: OverlayEffectApplicatorType) -> ExportEffect {
    // Ouput image should be created from cgImage reference
    var image: UIImage?
    
    switch type {
      case .gif:
        image = createGifImage()
      case .text:
        image = createTextImage()
     default:break
    }
    
    
    guard let outputImage = image else {
      fatalError("Overlay image should be provided")
    }
    
    // Create required effect settings
    let info = createEffectInfo(
      withImage: outputImage,
      for: type,
      start: .zero,
      end: totalVideoDuration
    )
    
    return ExportEffect(
      type: .overlay,
      id: uniqueEffectId,
      startTime: .zero,
      endTime: totalVideoDuration,
      additionalInfo: [
        ExportEffectAdditionalInfoKey.name: type,
        ExportEffectAdditionalInfoKey.effectInfo: info
      ]
    )
  }

  // MARK: - ExportEffectProvider helper
  private func createEffectInfo(
    withImage image: UIImage,
    for type: OverlayEffectApplicatorType,
    start: CMTime,
    end: CMTime
  ) -> VideoEditorEffectInfo {
    
    // Relevant screen points
    var points: ImagePoints?
    
    switch type {
      case .gif:
        points = gifImagePoints
      case .text:
        points = textImagePoints
      default: break
    }
    
    
    // Result effect info
    let effectInfo = VideoEditorEffectInfo(
      id: UInt.random(in: 0...1000),
      image: image,
      relativeScreenPoints: points,
      start: start,
      end: end
    )
    
    return effectInfo
  }
  
  // MARK: - ImagePoints helpers
  /// Gif image points
  var gifImagePoints: ImagePoints {
    ImagePoints(
      leftTop: CGPoint(x: 0.15, y: 0.45),
      rightTop: CGPoint(x: 0.8, y: 0.45),
      leftBottom: CGPoint(x: 0.15, y: 0.55),
      rightBottom: CGPoint(x: 0.8, y: 0.55)
    )
  }
  
  /// Text image points
  var textImagePoints: ImagePoints {
    ImagePoints(
      leftTop: CGPoint(x: 0.15, y: 0.25),
      rightTop: CGPoint(x: 0.8, y: 0.25),
      leftBottom: CGPoint(x: 0.15, y: 0.35),
      rightBottom: CGPoint(x: 0.8, y: 0.35)
    )
  }
  
  // MARK: - Text Image
  /// Create text image
  func createTextImage() -> UIImage?{
    // Background creation
    let height = 40
    let width = 120
    
    let numComponents = 3
    let numBytes = height * width * numComponents
    
    let pixelData = [UInt8](repeating: 210, count: numBytes)
    let colorspace = CGColorSpaceCreateDeviceRGB()
    
    let rgbData = CFDataCreate(nil, pixelData, numBytes)!
    let provider = CGDataProvider(data: rgbData)!
    
    let rgbImageRef = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 8 * numComponents,
      bytesPerRow: width * numComponents,
      space: colorspace,
      bitmapInfo: CGBitmapInfo(rawValue: 0),
      provider: provider,
      decode: nil,
      shouldInterpolate: true,
      intent: CGColorRenderingIntent.defaultIntent
    )!
    
    let image = UIImage(cgImage: rgbImageRef)
    
    // Text creation
    UIGraphicsBeginImageContext(image.size)
    
    let text = "Hello world!"
    let rect = CGRect(origin: .zero, size: image.size)
    image.draw(in: rect)
    
    let font = UIFont(name: "Helvetica-Bold", size: 14)!
    let textColor = UIColor.white
    let textStyle = NSMutableParagraphStyle()
    textStyle.alignment = .center
    
    let attributes = [
      NSAttributedString.Key.font: font,
      NSAttributedString.Key.paragraphStyle: textStyle,
      NSAttributedString.Key.foregroundColor: textColor
    ]
    
    let textHeight = font.lineHeight
    let textY = (image.size.height - textHeight) / 2
    let textRect = CGRect(
      x: .zero,
      y: textY,
      width: image.size.width,
      height: textHeight
    )
    
    text.draw(in: textRect.integral, withAttributes: attributes)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    return result
  }
  
  // MARK: - Gif image
  /// Create gif from sample resource
  func createGifImage() -> UIImage? {
    guard let path = Bundle.main.path(forResource: "GifExample", ofType: "gif") else {
      print("Gif does not exist at that path")
      return nil
    }
    
    let url = URL(fileURLWithPath: path)
    guard let gifData = try? Data(contentsOf: url),
          let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else {
      return nil
    }
    
    var images = [UIImage]()
    let imageCount = CGImageSourceGetCount(source)
    for i in 0 ..< imageCount {
      if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
        images.append(UIImage(cgImage: image))
      }
    }
    
    let gifImage = UIImage.animatedImage(with: images, duration: 0.4)
    
    return gifImage
  }
}
