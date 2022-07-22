[![](https://www.banuba.com/hubfs/Banuba_November2018/Images/Banuba%20SDK.png)](https://www.banuba.com/video-editor-sdk)

# Banuba VEExportSDK. API Reference.

`VEExportSDK` allows you to export video composition which already setuped in [Core API](https://github.com/Banuba/VideoEditor-iOS) and optionally edited with [Effects API](https://github.com/Banuba/BanubaVideoEditorEffectsSDK-iOS). So [Core API](https://github.com/Banuba/VideoEditor-iOS) is requires usage for `VEExportSDK`.

- [Facade](#Facade)
- [ExportVideoInfo](#ExportVideoInfo)
- [Slideshow](#Slideshow)

## Facade

Facade (`VEExport` entity) consists of several methods and constructor.

`VEExport` initialization requires instance of `VideoEditorService`.

``` swift
  /// VEExport constructor.
  public init(
    videoEditorService: VideoEditorService
  )
```

Public methods allows you to export existing video editor composition or audio from `VideoEditorService` core module.

``` swift
  /// Export video with input info and watermark model
  /// - Parameters:
  ///   - fileURL: destination file url.
  ///   - exportVideoInfo: Describes exporting video editor params.
  ///   - watermarkFilterModel: Watermark effect.
  ///   - completion: completion creation - (isSuccess,  error)
  public func exportVideo(
    to fileURL: URL,
    using exportVideoInfo: ExportVideoInfo,
    watermarkFilterModel: VideoEditorFilterModel?,
    completion: ((_ isSuccess: Bool, _ error: Error?)-> Void)?
  )
  
  /// Export audio from video editor asset
  /// - Parameters:
  ///   - fileURL: destination file url.
  ///   - completion: completion creation - (isSuccess,  error)
  public func exportAudio(
    to fileURL: URL,
    completion:((_ isSuccess: Bool, _ error: Error?)->Void)?
  )
```

Also `VEExport` API allows you to create slideshow from entire images.
``` swift
  /// Exports slideshow images to fileUrl if provided. Otherwise, will be exported to tmp folder.
  /// - Parameters:
  ///   - images: images which will be used for slideshow
  ///   - fileUrl: destination file url. Optional.
  ///   - videoResolution: camera Module used to control device camera. Default is BanubaCameraModule
  ///   - completion: completion slideshow creation - (success, slideshow file url, error)
  public func exportSlideshowImages(
    _ images: [VideoEditorImageAssetProtocol],
    to fileUrl: URL? = nil,
    videoResolution: VideoResolution,
    completion: ((Bool, URL, Error?) -> Void)?
  ) 
```

## ExportVideoInfo

Following entity is representation of export settings such as resolution, framerate, scaling mode and condition for using hevc codec.

``` swift
/// Create configurable export video parameters.
public class ExportVideoInfo {
  /// Specified video quality.
  public let resolution: Resolution
  
  /// Specified video aspect.
  public let aspect: AspectRatio?
  
  /// Export video settings
  public let exportSettings: ExportVideoSettings
  
  /// ExportVideoInfo constructor.
  /// - Parameters:
  ///   - resolution: Specify quality for exporting video.
  ///   - aspect: Specify video aspect.
  ///   - useHEVCCodecIfPossible: Use HEVC (H.265) encoder if it is available on the current device
  ///   - frameRate: Specify video frame rate. Default is 30.
  ///   - scalingMode: Specify video scaling mode with required mode like ‘AVVideoScalingModeResizeAspect’. Default is 'AVVideoScalingModeResize'.
  public init(
    resolution: Resolution,
    aspect: AspectRatio? = nil,
    useHEVCCodecIfPossible: Bool,
    frameRate: Int = 30,
    scalingMode: String = AVVideoScalingModeResize
  )
}
```

Resolution options.
``` swift
  /// Specified quality for exporting video.
  public enum Resolution: String {
    /// 360p
    case ld360
    /// 480p
    case md480
    /// 540p
    case md540
    /// 720p
    case hd720
    /// 1080p
    case fullHd1080
    /// original
    case original
    /// 2K
    case hd2K
  }
```

## Slideshow

As mentioned above API has functionality to create slideshow video from images.
Entire Images should be inherit from `VideoEditorImageAssetProtocol.

``` swift
public protocol VideoEditorImageAssetProtocol: AnyObject {
  /// Slideshow duration
  var duration: TimeInterval { get }
  /// Image for video creation usage
  var image: CGImage? { get }
  /// Is need to use scaling effects during slideshow
  var shouldUseImageEffect: Bool { get }
  /// Get current CGImage from slideshow
  func getOrPreloadImage() -> CGImage?
  /// Remove existing image
  func unloadImage()
}
```
