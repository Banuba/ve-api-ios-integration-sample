[![](https://www.banuba.com/hubfs/Banuba_November2018/Images/Banuba%20SDK.png)](https://www.banuba.com/video-editor-sdk)

# Banuba VEEffectsSDK. API Reference.

`VEEffectsSDK` allows you to edit video composition which already setuped in [Core API](https://github.com/Banuba/VideoEditor-iOS). So [Core API](https://github.com/Banuba/VideoEditor-iOS) is requires usage for `VEEffectsSDK`.

`VEEffectSDK` consists of several effect applicators:
  - [Effects Applicator](#Effects-Applicator)
      + [FX effects functionality](#FX-effects-functionality)
      + [Speed effects functionality](#Speed-effects-functionality)
      + [Overlay effects functionality](#Overlay-effects-functionality)
          + [Pixelization](#Pixelization)
      + [Transform effects functionality](#Overlay-effects-functionality)
  - [Watermark Applicator](#Watermark-Applicator)
  - [Pixelate Applicator](#Pixelate-Applicator)

## Effects Applicator

Effects Applicator is used for applying visual effects, such as fx, speed, overlay, transform effects.
Each method contains set of entire options to setup effect settings: time, type, condition to remove same type and etc.

:exclamation: **Important:** **Effect ID should be unique for each added effect.**

`EffectApplicator` constructor requires `VideoEditorService` and `EditorEffectsConfigHolder` instances.
``` swift
  /// EffectApplicator constructor
  /// - Parameters:
  ///   - editor: Instance of existing VideoEditorService
  ///   - effectConfigHolder: Instance of existing EditorEffectsConfigHolder
  ///   - videoSize: Watermark video size
  required public init(
    editor: VideoEditorServicing,
    effectConfigHolder: EffectsHolderServicing
  )
```

### FX effects functionality

`applyVisualEffectApplicatorType` func of `EffectApplicator` entity allows you to add choosen visual effect to video composition of `VideoEditorService`.
``` swift
  /// Allows you to add visual effects with required settings.
  /// - Parameters:
  ///   - type: Describes what kind of effect needs to be added
  ///   - startTime: When effect starts
  ///   - endTime: When effect ends
  ///   - removeSameType: Remove same effect if exist
  ///   - effectId: Unic effect id
  func applyVisualEffectApplicatorType(
    _ type: VisualEffectApplicatorType,
    startTime: CMTime,
    endTime: CMTime,
    removeSameType: Bool,
    effectId: UInt
  )
```

`VisualEffectApplicatorType` options
``` swift
/// VisualEffectApplicatorType describes what kind of effect needs to be added
public enum VisualEffectApplicatorType: String, CaseIterable {
  /// acid effect type
  case acid
  /// cathode effect type
  case cathode
  /// dslrKaleidoscope effect type
  case dslrKaleidoscope
  /// dvCam effect type
  case dvCam
  /// flash effect type
  case flash
  /// glitch2 effect type
  case glitch2
  /// glitch3 effect type
  case glitch3
  /// glitch effect type
  case glitch
  /// glitchEffect2 effect type
  case glitchEffect2
  /// kaleidoscope effect type
  case kaleidoscope
  /// heatmap effect type
  case heatmap
  /// lumeire effect type
  case lumeire
  /// pixelationDynamic effect type
  case pixelationDynamic
  /// pixelationStatic effect type
  case pixelationStatic
  /// polaroid effect type
  case polaroid
  /// rave effect type
  case rave
  /// soul effect type
  case soul
  /// stars effect type
  case stars
  /// transition effect type
  case transition
  /// transition2 effect type
  case transition2
  /// transition3 effect type
  case transition3
  /// transition4 effect type
  case transition4
  /// tvFoam effect type
  case tvFoam
  /// vhs effect type
  case vhs
  /// vhs2 effect type
  case vhs2
  /// zoom effect type
  case zoom
  /// zoom2 effect type
  case zoom2
}
```

### Speed effects functionality

`applySpeedEffectType` func of `EffectApplicator` entity allows you to add choosen speed effect to video composition of `VideoEditorService`.
``` swift
  /// Allows you to add speed effects with required settings.
  /// - Parameters:
  ///   - type: Describes what kind of effect needs to be added
  ///   - startTime: When effect starts
  ///   - endTime: When effect ends
  ///   - removeSameType: Remove same effect if exist
  ///   - effectId: Unic effect id
  func applySpeedEffectType(
    _ type: SpeedEffectType,
    startTime: CMTime,
    endTime: CMTime,
    removeSameType: Bool,
    effectId: UInt
```

`SpeedEffectType` options.
``` swift
/// SpeedEffectType describes what kind of effect needs to be added
public enum SpeedEffectType: String, CaseIterable {
  /// slowmo effect type
  case slowmo
  /// rapid effect type
  case rapid
}
```

### Overlay effects functionality

`applyOverlayEffectType` func of `EffectApplicator` entity allows you to add choosen overlay effect to video composition of `VideoEditorService`.
``` swift
  /// Allows you to add GIF or text effects with required settings.
  /// - Parameters:
  ///   - type: Describes what kind of effect needs to be added
  ///   - effectInfo: Contains all the information you need to add effects to your video.
  func applyOverlayEffectType(
    _ type: OverlayEffectApplicatorType,
    effectInfo: VideoEditorEffectInfo
  )
```

`OverlayEffectApplicatorType` options.
``` swift
/// OverlayEffectApplicatorType describes what kind of effect needs to be added
public enum OverlayEffectApplicatorType {
  /// Gif effect type
  case gif
  /// Text effect type
  case text
  /// Pixelate effect type
  case pixelate(
    drawableFigure: DrawableFigure,
    coordinates: PixelateCoordinateParams
  )
}
```

Effect info options. Main property is image which used as entire effect.

:exclamation: **Important:** **Image should be create from CGImage represenation.**

``` swift
/// VideoEditorEffectInfo contains all the information you need to add effects to your video.
public struct VideoEditorEffectInfo {
  /// Effect id
  public private(set) var id: UInt
  /// Effect snapshot
  public private(set) var image: UIImage?
  /// Describes the relative screen points of the effects on the screen
  public private(set) var relativeScreenPoints: ImagePoints?
  /// When effect starts
  public private(set) var start: CMTime
  /// When effect ends
  public private(set) var end: CMTime
 }
```

#### Pixelization

Pixelate case requires additional options:
 - Type of drawable figure:
 ``` swift
/// Possible shapes to draw the effect pixelate
public enum DrawableFigure: Codable {
  // draw circle
  case circle
  // draw square
  case square
}
 ```
 - Coordinate params for pixelate effect:
 ``` swift
 /// Blur effect coordinate parameters 
public struct PixelateCoordinateParams: Codable {
  /// Center point
  public var center: CGPoint
  /// Effect width
  public var width: CGFloat
  /// Effect height
  public var height: CGFloat
  /// Effect radius
  public var radius: CGFloat

  /// Center point in absolute frame. Value ranges from 0 to 100.
  public var absoluteCenter: CGPoint
  /// Radius in absolute frame. Value ranges from 0 to 100.
  public var absoluteRadius: CGFloat
}
 ```
 
 ### Transform effects functionality
 
 Transform effects used for asset rotation by the clockwise coordinates.
 ``` swift
  /// Allows you to add rotation effect with required settings.
  /// - Parameters:
  ///   - atStartTime: When effect is need to be start
  ///   - end: When effect is need to be end
  ///   - rotation: Video rotation settings
  ///   - isVideoFitsAspect: Describes if video fits entire aspect view port
  public func addTransformEffect(
    atStartTime start: CMTime,
    end: CMTime,
    rotation: AssetRotation,
    isVideoFitsAspect: Bool
  )
 ```
 
 Rotation options.
 ``` swift
 /// Video rotation settings
public enum AssetRotation: UInt8, Codable {
  /// Zero degrees
  case none = 0
  /// 90 degrees
  case rotate90 = 1
  /// 180 degrees
  case rotate180 = 2
  /// 270 degrees
  case rotate270 = 3
}
 ```
 
 ## Watermark Applicator
 
Watermark Applicator is used for adjusting watermarks filter models for subsequent usage with VEExportSDK.
Method contains set of entire options to setup effect settings: configuration and preffered video size of exporting `VideoEditorService` composition.

``` swift
/// Returns VideoEditorFilterModel with given configuration
  /// - Parameters:
  ///   - configuration: Watermark configuration
  ///   - videoSize: Watermark size
  public func adjustWatermarkEffect(
    configuration: WatermarkConfiguration,
    videoSize: CGSize
  )
```

`WatermarkConfiguration` consist of Image configuration of relevant watermark representation, size, offset, screen position and id.

:exclamation: **Important:** **Effect ID should be unique for each added effect.**

``` swift 
/// The watermark configuration.
public struct WatermarkConfiguration {
  /// The watermark image configuration
  public var watermark: ImageConfiguration
  /// The watermark size configuration.
  public var size: CGSize
  /// The watermark offset from edges.
  public var sharedOffset: CGFloat
  /// The watermark position.
  public var position: WatermarkPosition
  /// Id. Used for internal expired watermark.
  public var id: UInt?
  
  /// Describes where watermark appears
  public enum WatermarkPosition {
    case leftTop
    case leftBottom
    case rightTop
    case rightBottom
  }
}
```

## Pixelate Applicator

PixelateApplicator allows you to change current pixelate effect position and scale options.
`changeTextureLocation` func requires pixelate effect drawable figure, shapeRenderer and coordinates. So you need to store id of pixelate effect for subsequent getting relevant shape renderer from `VideoEditorService` entity with method getCurrentAppliedEffects. Then you could filter them with existing id and get renderer instance from model with following casting to pass it to `changeTextureLocation` func.
``` swift
let shapeRenderer = model.rendererInstance as? ShapeDrawer
```

`changeTextureLocation` func
``` swift
  /// Change blur texture location
  /// - Parameters:
  ///  - drawableFigure: Circle or Square figure.
  ///  - shapeRenderer:  Renderer instance.
  ///  - coordinates: Coordinate params to entire texture.
  ///  - completion: Calls when texture changed.
  func changeTextureLocation(
    drawableFigure: DrawableFigure,
    shapeRenderer: ShapeDrawer,
    coordinates: PixelateCoordinateParams,
    completion: (() -> Void)?
  )
```

