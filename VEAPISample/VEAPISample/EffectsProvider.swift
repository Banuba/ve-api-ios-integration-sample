
import VEEffectsSDK
import UIKit
import AVFoundation
import BanubaUtilities
import VEEffectsSDK
import VideoEditor

/// This effects provider applies effect to full video duration
class EffectsProvider {
    /// Unique effect id
    var generatedEffectUuid: String {
        UUID().uuidString
    }
    
    var generatedEffectId: UInt {
        UInt.random(in: 0...100)
    }
    
    // AR Mask should be located in effects folder
    func provideMaskEffect(withName maskName: String) -> VideoEditorFilterModel {
        let maskUrl = Bundle.main.bundlePath + "/effects/" + maskName
        
        var isDirectory = ObjCBool(true)
        
        guard FileManager.default.fileExists(atPath: maskUrl, isDirectory: &isDirectory) else {
            fatalError("Cannot find AR mask effect! Please check if AR mask effect exists")
        }
        
        let effectId = EffectIDs.maskEffectStartId + generatedEffectId
        
        return VideoEditorFilterModel(
            name: maskName,
            type: .mask,
            renderer: BanubaMaskDrawer.self,
            path: maskUrl,
            id: effectId,
            tokenId: "\(effectId)",
            rendererInstance: nil,
            preview: nil,
            additionalParameters: nil
        )
    }
    
    // Returns music effect
    func provideMusicEffect() -> MediaTrack {
        guard let audioUrl = Bundle.main.url(forResource: "sample", withExtension: "wav") else {
            fatalError("Can't find music track")
        }
        
        let trackTimeRange = CMTimeRange(
            start: .zero,
            duration: AVAsset(url: audioUrl).duration
        )
        
        // Track time range
        let timeRange = MediaTrackTimeRange(
            startTime: .zero,
            playingTimeRange: trackTimeRange
        )
        
        // Track instance
        return MediaTrack(
            uuid: UUID(),
            id: CMPersistentTrackID(generatedEffectId),
            url: audioUrl,
            timeRange: timeRange,
            isEditable: true,
            title: "sample"
        )
    }
    
    func provideTextEffect(duration: CMTime) -> VideoEditorEffectInfo {
        let points = ImagePoints(
            leftTop: CGPoint(x: 0.15, y: 0.25),
            rightTop: CGPoint(x: 0.8, y: 0.25),
            leftBottom: CGPoint(x: 0.15, y: 0.35),
            rightBottom: CGPoint(x: 0.8, y: 0.35)
        )
        
        return VideoEditorEffectInfo(
            uuid: generatedEffectUuid,
            image: createTextImage(text: "Hello world!", font: UIFont(name: "Helvetica-Bold", size: 14)!),
            relativeScreenPoints: points,
            start: .zero,
            end: duration
        )
    }
    
    func provideStickerEffect(duration: CMTime) -> VideoEditorEffectInfo {
        let points = ImagePoints(
            leftTop: CGPoint(x: 0.15, y: 0.45),
            rightTop: CGPoint(x: 0.8, y: 0.45),
            leftBottom: CGPoint(x: 0.15, y: 0.55),
            rightBottom: CGPoint(x: 0.8, y: 0.55)
        )
        
        guard let path = Bundle.main.path(forResource: "GifExample", ofType: "gif") else {
            fatalError("Cannot find GIF file")
        }
        
        guard let gifData = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else {
            fatalError("Cannot create GIF data")
        }
        
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        
        let gifImage = UIImage.animatedImage(with: images, duration: 0.4)
        
        return VideoEditorEffectInfo(
            uuid: generatedEffectUuid,
            image: gifImage,
            relativeScreenPoints: points,
            start: .zero,
            end: duration
        )
    }
    
    // MARK: - Text Image
    /// Create text image
    private func createTextImage(text: String, font: UIFont) -> UIImage?{
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
        
        let rect = CGRect(origin: .zero, size: image.size)
        image.draw(in: rect)
        
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
}
