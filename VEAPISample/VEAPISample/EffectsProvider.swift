//
//  EffectsProvider.swift
//  VEAPISample
//
//  Created by Andrey Sak on 19.12.22.
//

import VEEffectsSDK
import UIKit
import BanubaUtilities

/// Available effect types
enum EffectType {
  case color
  case visual
  case speed
  /// gif, text or blur
  case overlay
  case mask
  case music
}

/// Effect contains info about type, id, timeRange in asset and additional info
struct Effect {
  /// Unique id of effect
  let id: UInt
  /// Type of effect
  let type: EffectType
  /// Time range of video asset which will be applied by effect
  let timeRange: CMTimeRange
  /// Additional values required by effect
  let additionalInfo: [String: Any]
  
  /// Additional info keys required by effect
  struct AdditionalInfoKey {
    /// Effect url
    static let url: String = "url"
    /// Effect name
    static let name: String = "name"
    /// Additional effect settings
    static let effectSettings: String = "effectSettings"
  }
}

/// This effects provider applies effect to full video duration
class EffectsProvider {
  /// Unique effect id
  var uniqueEffectId: UInt {
    UInt.random(in: 0...100)
  }
  
  private var totalVideoDuration: CMTime = .zero
  
  init(totalVideoDuration: CMTime) {
    self.totalVideoDuration = totalVideoDuration
  }
  
  // provides all available effect
  func provideAllEffects() -> [Effect] {
    return [
      provideMaskEffect(),
      provideColorEffect(),
      provideVisualEffect(type: .vhs),
      provideSpeedEffect(type: .slowmo),
      provideOverlayEffect(type: .gif),
      provideOverlayEffect(type: .text),
      provideMusicEffect()
    ]
  }
  
  // Returns mask effect with specific name. Mask should be located in effects folder.
  func provideMaskEffect(withName maskName: String = "AsaiLines") -> Effect {
    let url = Bundle.main.bundlePath + "/effects/" + maskName
    var isDirectory = ObjCBool(true)
    guard FileManager.default.fileExists(atPath: url, isDirectory: &isDirectory) else {
      fatalError("Unable to find mask at specified url")
    }
    
    return Effect(
      id: EffectIDs.maskEffectStartId + uniqueEffectId,
      type: .mask,
      timeRange: CMTimeRange(start: .zero, duration: totalVideoDuration),
      additionalInfo: [
        Effect.AdditionalInfoKey.url: url,
        Effect.AdditionalInfoKey.name: maskName
      ]
    )
  }
  
  // Returns color effect
  func provideColorEffect() -> Effect {
    guard let url = Bundle.main.url(forResource: "luts/japan", withExtension: "png") else {
      fatalError("Unable to find color filter at specified url")
    }
    
    return Effect(
      id: EffectIDs.colorEffectStartId + uniqueEffectId,
      type: .color,
      timeRange: CMTimeRange(start: .zero, duration: totalVideoDuration),
      additionalInfo: [
        Effect.AdditionalInfoKey.url: url,
        Effect.AdditionalInfoKey.name: "Japan"
      ]
    )
  }
  
  // Returns visual effect for specific type
  func provideVisualEffect(type: VisualEffectApplicatorType) -> Effect {
    return Effect(
      id: EffectIDs.visualEffectStartId + uniqueEffectId,
      type: .visual,
      timeRange: CMTimeRange(start: .zero, duration: totalVideoDuration),
      additionalInfo: [Effect.AdditionalInfoKey.name: type]
    )
  }
  
  // Returns speed effect for specific type (rapid or slowmo)
  func provideSpeedEffect(type: SpeedEffectType) -> Effect {
    return Effect(
      id: EffectIDs.speedEffectStartId + uniqueEffectId,
      type: .speed,
      timeRange: CMTimeRange(start: .zero, duration: totalVideoDuration),
      additionalInfo: [Effect.AdditionalInfoKey.name: type]
    )
  }
  
  // Returns music effect
  func provideMusicEffect() -> Effect {
    guard let url = Bundle.main.url(forResource: "sample", withExtension: "wav") else {
      fatalError("Can't find music track")
    }
    
    return Effect(
      id: uniqueEffectId,
      type: .music,
      timeRange: CMTimeRange(start: .zero, duration: totalVideoDuration),
      additionalInfo: [
        Effect.AdditionalInfoKey.name: "sample",
        Effect.AdditionalInfoKey.url: url
      ]
    )
  }
  
  // Returns overlay effect for specific type
  func provideOverlayEffect(type: OverlayEffectApplicatorType) -> Effect {
    // Ouput image should be created from cgImage reference
    var image: UIImage?
    
    switch type {
      case .gif:
        image = createGifImage()
      case .text:
        image = createTextImage()
     default: break
    }
    
    let timeRange = CMTimeRange(start: .zero, duration: totalVideoDuration)
    
    // Create required effect settings
    let effectSettings = createEffectSettings(
      withImage: image,
      for: type,
      start: timeRange.start,
      end: timeRange.end
    )
    
    return Effect(
      id: uniqueEffectId,
      type: .overlay,
      timeRange: timeRange,
      additionalInfo: [
        Effect.AdditionalInfoKey.name: type,
        Effect.AdditionalInfoKey.effectSettings: effectSettings
      ]
    )
  }

  // MARK: - EffectsProvider helper
  private func createEffectSettings(
    withImage image: UIImage?,
    for type: OverlayEffectApplicatorType,
    start: CMTime,
    end: CMTime
  ) -> VideoEditorEffectInfo {
    
    // Relevant normilized positions of overlay
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
      id: uniqueEffectId,
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
