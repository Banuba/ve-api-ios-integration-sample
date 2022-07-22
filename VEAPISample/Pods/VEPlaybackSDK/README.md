[![](https://www.banuba.com/hubfs/Banuba_November2018/Images/Banuba%20SDK.png)](https://www.banuba.com/video-editor-sdk)

# Banuba VEPlaybackSDK. API Reference.

`VEPlaybackSDK` allows you to display already setuped video composition from [Core API](https://github.com/Banuba/VideoEditor-iOS) and optionally edited with [Effects API](https://github.com/Banuba/BanubaVideoEditorEffectsSDK-iOS). So [Core API](https://github.com/Banuba/VideoEditor-iOS) is requires usage for `VEPlaybackSDK`.

- [Facade](#Facade)
- [Player entity](#Player-entity)
    + [Playback functionality](#Playback-functionality)
    + [Rewind functionality](#Rewind-functionality)
    + [Reload functionality](#Reload-functionality)
    + [Playback related properties](#Playback-related-properties)
- [VideoEditorPlayerDelegate](#VideoEditorPlayerDelegate)
- [View with player implementation](#View-with-player-implementation)

## Facade

Facade (`VEPlayback` entity) consists of several methods and constructor.

`VEPlayback` initialization requires instance of `VideoEditorService`.

``` swift
  /// VEPlayback constructor.
  public init(
    videoEditorService: VideoEditorService
  ) 
```

Public methods allows you to get preffered instance of pure player or already setuped playable preview with player implementation.

``` swift
  /// Allows you to get player instance with current videoEditorService asset composition.
  /// - parameters:
  ///   - forAsset: Relevant asset. Except current videoEditorService asset composition.
  ///   - delegate: Delegation link.
  public func getPlayer(
    forExternalAsset asset: AVAsset? = nil,
    delegate: VideoEditorPlayerDelegate?
  ) -> VideoEditorPlayable
  
  /// Allows you to get playable view instance with current videoEditorService asset composition.
  /// - parameters:
  ///   - isThumbnailNeeded: Allows you to create preview thumbnail for UIImageView image reference. Default is true.
  ///   - forAsset: Relevant asset. Except current videoEditorService asset composition.
  ///   - delegate: Delegation link.
  public func getPlayableView(
    isThumbnailNeeded: Bool = true,
    forExternalAsset asset: AVAsset? = nil,
    delegate: VideoEditorPlayerDelegate?
  ) -> VideoPlayableView
```

## Player entity

The `VideoEditorPlayable` interface consists of a lot of methods that allow you to work with the playback of the player, its settings, reload and related properties of the asset, time, etc.

### Playback functionality
``` swift
  /// Start playing with parameters.
  ///  - parameters:
  ///   - loop: Is need to loop video.
  ///   - fixedSpeed: Describes whenever video has different speed references.
  func startPlay(loop: Bool, fixedSpeed: Bool)
  /// Start playing with parameters.
  ///  - parameters:
  ///   - loop: Is need to loop video.
  ///   - fixedSpeed: Describes whenever video has different speed references.
  ///   - start: When video should start.
  ///   - end: When video should end.
  func startPlay(loop: Bool, fixedSpeed: Bool, start: CMTime, end: CMTime)
  /// Start or stop playing with parameters. Depends on current player state.
  ///  - parameters:
  ///   - loop: Is need to loop video.
  ///   - fixedSpeed: Describes whenever video has different speed references.
  func startStopPlay(loop: Bool, fixedSpeed: Bool)

  /// Pause player.
  func pausePlay()
  /// Stop player.
  func stopPlay()
  /// Resume player.
  func resumePlay()
```

### Rewind functionality
``` swift
  /// Seek and stop player with chosen time.
  ///  - parameters:
  ///   - to: Seek time.
  func smoothlySeek(to time: CMTime)
  /// Seek player with chosen time.
  ///  - parameters:
  ///   - to: Seek time.
  func seek(to time: CMTime)
```

### Reload functionality
```swift
  /// Reload player preview.
  func reloadPreview()
  /// Reload player preview with options.
  ///  - parameters:
  ///   - shouldAutoStart: Should autostart player after reloading .
  func reloadPreview(shouldAutoStart: Bool)
  /// Reload player composition with options.
  func reloadComposition(shouldAutoStart: Bool)
```

### Playback related properties
``` swift
   /// Is player in playing state.
  var isPlaying: Bool { get }
  /// Is player muted.
  var isMuted: Bool { get set }
  
  /// Current player item.
  var playerItem: AVPlayerItem? { get }
  /// Audio volume parameters.
  var audioMix: AVAudioMix? { get set }
  
  /// Player delegate.
  var playerDelegate: VideoEditorPlayerDelegate? { get set }
  
  /// Current AVPlayer instance.
  var avPlayer: AVPlayer { get }
  
  /// Current player time.
  var currentTime: TimeInterval { get }
  /// Duration of video.
  var videoDuration: Double { get }
  
  /// Current player time in CMTime presentation.
  var currentTimeInCMTime: CMTime { get }
  /// Video duration time in CMTime presentation.
  var videoDurationCMTime: CMTime { get }
  /// Start time in CMTime presentation.
  var startTimePlay: CMTime { get }
  /// End time in CMTime presentation.
  var endTimePlay: CMTime { get }
```

## VideoEditorPlayerDelegate

The delegate will allow you to catch the moments when the player is playing with a specific time, as well as when it finishes playing.
``` swift
  /// Calls every time when frame displayed during playing.
  ///  - parameters:
  ///   - player: Current player instance.
  ///   - atTime: Relevant playing time.
  func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime)
  /// Calls when player did end playing.
  ///  - parameters:
  ///   - player: Current player instance.
  func playerDidEndPlaying(_ player: VideoEditorPlayable)
```

## View with player implementation

`VideoPlayableView` is already setuped render view with player implementation which allows you to display applied VEEffectsSDK effects and manage player states using `VideoEditorPlayable` interface.

Setup method which allows you to apply newest player to existing playable view render layer. 
```swift
  /// Allows you to setup player with relevant preview layer.
  /// - parameters:
  ///  - player: instance of AVPlayer. Optional.
  ///  - isThumbnailNeeded: Allows you to create preview thumbnail for UIImageView image reference.
  func setPlayer(_ player: VideoEditorPlayable?, isThumbnailNeeded: Bool)
```

Related properties.
Layer is `AVPlayerLayer` representation of playable view. 
Image generator is need for thumbnail creation if `VideoEditorPlayable` using like cover choosing entity.
``` swift
  /// Layer instance of UIImageView casted to AVPlayerLayer.
  var previewLayer: AVPlayerLayer { get }
  /// Image generator
  var imageGenerator: AVAssetImageGenerator? { get set }
```

Player properties.
``` swift
  /// Player instance of VE
  var videoEditorPlayer: VideoEditorPlayable? { get set }
  /// Player instance of previewLayer.
  var player: AVPlayer? { get }
```
