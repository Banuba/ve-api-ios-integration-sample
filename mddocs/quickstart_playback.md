# Quickstart Playback API

- [Overview](#Overview)
- [Prerequisites](#Prerequisites)
- [Prepare video player](#Prepare-video-player)
- [Release video player](#Release-video-player)
- [Set event callback](#Set-event-callback)
- [Add video playlist](#Add-video-playlist)
- [Manage video player actions](#Manage-video-player-actions)
- [Add audio track](#Add-audio-track)
- [Manage effects](#Manage-effects)

## Overview
This guide is aimed to quickly help you integrate Playback API into your iOS project.
You will learn how to use core features and build use cases to meet your product requirements.

## Prerequisites
Please complete [Installation](../README.md#Installation) and [Setup API](overview.md#Setup-API) steps before to proceed.

Create class [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift) for implementing Playback API functionality.
```Swift
class PlaybackManager: VideoEditorPlayerDelegate {
...
}
```

## Prepare video player
```VideoPlayableView```, ```VideoEditorPlayable```, ```VEPlayback``` are main classes for implementing Playback API.  

```VideoEditorPlayable``` is similar to media player and responsible for controlling video playback. ```VideoPlayableView``` is a view component and is required 
to get instance ```VideoEditorPlayable```. 

First, create instance [playbackSDK](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L41) using ```VideoEditorService```
```Swift
init(videoEditorModule: VideoEditorApiModule) {
    self.videoEditorService = videoEditorModule.editor
    self.playbackSDK = VEPlayback(videoEditorService: videoEditorService)
    ...
}
```

Next, add [UIView container](../VEAPISample/VEAPISample/Playback/PlaybackViewController.swift#L19) to your screen where you want to play video. 
Pass this ```UIView``` to [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L81) to add ```VideoPlayableView``` as a subview.
```Swift
let playerContainerView: UIView = ...
let playbackView = playbackSDK.getPlayableView(delegate: self)
playerContainerView.addSubview(playbackView)
```

And finally use ```playbackView.videoEditorPlayer``` to get instance of player in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L14).

## Release video player
It is highly recommended to stop and release video player if the user leaves the screen.  

You should release usage of video content using ```videoEditorService.setCurrentAsset(nil)``` 
in [PlaybackManager.deinit](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L51).

```Swift
deinit { 
// Clear video editor service asset
videoEditorService.setCurrentAsset(nil)
...
}
```

## Set event callback
Implement ```VideoEditorPlayerDelegate``` in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L7) to handle received events from the player.
You could set it while creating ```VideoPlayableView``` in ```let playbackView = playbackSDK.getPlayableView(delegate: self)```
```Swift
/// Player delegate
public protocol VideoEditorPlayerDelegate : AnyObject {

    /// Calls every time when frame displayed during playing.
    ///  - parameters:
    ///   - player: Current player instance.
    ///   - atTime: Relevant playing time.
    func playerPlaysFrame(_ player: BanubaUtilities.VideoEditorPlayable, atTime time: CMTime)

    /// Calls when player did end playing.
    ///  - parameters:
    ///   - player: Current player instance.
    func playerDidEndPlaying(_ player: BanubaUtilities.VideoEditorPlayable)
}
```

Moreover, you can implement custom progress [callback](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L12) to track playback position and 
handle it in [ViewController](../VEAPISample/VEAPISample/Playback/PlaybackViewController.swift#L35).

## Add video playlist
Use [VideoEditorService.setCurrentAsset()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L71) method and pass ```VideoEditorAsset```
to add video playlist you want to play. ```VideoSequence``` is a class in Playback API and Export API which is responsible for
describing video source and its capabilities i.e. speed, start and end positions of video to export etc.

>:exclamation: **Note:** ```VideoEditorPlayable``` supports playing video stored on the device and the following [media formats](../README.md#Supported-media-formats).

>:bulb: **Hint:** You might have a list of video sources as ```[URL]``` that are stored on the device. You should convert ```[URL]``` to ```VideoEditorAsset```
by providing required properties and especially video playing boundaries.


## Manage video player actions
```VideoEditorPlayable``` supports a number of well known player action methods for controlling video playback
- [VideoEditorPlayable.startPlay()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L117)
- [VideoEditorPlayable.stopPlay()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L121)
- [VideoEditorService.setAudioTrackVolume()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L90)
- [VideoEditorPlayable.seek()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L124)

Use [VideoEditorPlayable.startPlay()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L117) to play video when the player is prepared and video playlist is set
```Swift
player?.startPlay(loop: loop, fixedSpeed: false) // loop = true - repeat playing
```

Implementing video trimming or editing features you might need to move playback to a certain position and set start and end
video playing boundaries. Use [VideoEditorPlayable.seek()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L124) method to move
playback to a certain position.

Position is represented as time in ```CMTime```. In this example, the player seeks to 5 second and 100 miliseconds position.
```Swift
let seekTime = CMTime(seconds: 5.100, preferredTimescale: 1_000)
player?.seek(to: seekTime)
```

## Add audio track
```VideoEditorPlayable``` supports adding additional audio track on top of the video's soundtrack. The additional audio track should be stored on the device. ```MediaTrack``` instance represents audio track.  
Use [addMusicTrack()](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L282) to set the audio track and play it in video player.
```Swift
editor.videoAsset?.addMusicTrack(track)
```
>:bulb: **Hint:** You might have an audio track as ```URL``` and you want to add it to video. Just convert ```URL``` to ```MediaTrack``` and set all required properties.
Implement managing what audio tracks the user adds and removes.

Please [check out](../VEAPISample/VEAPISample/EffectsProvider.swift#L41) full implementation
of converting ```URL``` to  ```MediaTrack``` and adding it to ```VideoEditorService```.

## Manage effects
```VideoEditorPlayable``` supports adding a various number of effects while video playback. Learn more [supported effects](https://github.com/Banuba/ve-sdk-ios-integration-sample/blob/main/mdDocs/advanced_integration.md#Add-effects).  
Video Editor API differs from Video Editor SDK in that API requires you to implement effect management on your side.
API includes very handy class ```EffectApplicator``` that simplifies effect management process.
Our sample includes handy class  [EffectsProvider](../VEAPISample/VEAPISample/EffectsProvider.swift) that implements simple effect creation process.

>:exclamation: **Important:** The license token includes the list of allowed ```FX``` and ```Speed``` effects. Crash might happen if the not allowed effect is used.

The following sections explain how to create various effects.
You should add it to the list of effects and then use ```EffectApplicator``` or ```VideoEditorService```.

>:bulb: **Note:** It is required to reload the player ```player.reloadComposition(shouldAutoStart: true)``` after 
> apply or undo any effect.

### Create color effect
In this example, a color effect that is applied to the whole video in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L146).
```"japan.png"``` is the name of the color effect located in [assets](../VEAPISample/VEAPISample/luts/japan.png) folder.
```Swift
guard let colorEffectUrl = Bundle.main.url(forResource: "luts/japan", withExtension: "png") else {
    fatalError("Cannot find color effect! Please check if color effect exists")
}
        
effectApplicator.applyColorEffect(
    name: "Japan",
    lutUrl: colorEffectUrl,
    startTime: .zero,
    endTime: totalVideoDuration,
    removeSameType: false,
    effectId: EffectIDs.colorEffectStartId + effectsProvider.generatedEffectId
)
        
player?.reloadComposition(shouldAutoStart: isPlaying)
```

### Create speed effect
In this example, ```Rapid``` and ```SlowMo``` speed effects are applied to the whole video in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L208).
```Swift
/// Rapid        
effectApplicator.applySpeedEffectType(
    .rapid,
    startTime: .zero,
    endTime: totalVideoDuration,
    removeSameType: false,
    effectId: EffectIDs.speedEffectStartId + effectsProvider.generatedEffectId
)
             
player?.reloadComposition(shouldAutoStart: isPlaying)

/// Slow Mo
effectApplicator.applySpeedEffectType(
    .slowmo,
    startTime: .zero,
    endTime: totalVideoDuration,
    removeSameType: false,
    effectId: EffectIDs.speedEffectStartId + effectsProvider.generatedEffectId
)
        
player?.reloadComposition(shouldAutoStart: isPlaying)
```

### Create FX effect
In this example, FX effect ```VHS``` is applied to the whole video in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L192).
```Swift
effectApplicator.applyVisualEffectApplicatorType(
    .vhs,
    startTime: .zero,
    endTime: totalVideoDuration,
    removeSameType: false,
    effectId: EffectIDs.visualEffectStartId + effectsProvider.generatedEffectId
)
        
player?.reloadComposition(shouldAutoStart: isPlaying)
```

### Create Sticker effect
In this example, we create Sticker effect. It requires ```.gif``` file stored on the device and ```Uri``` to locate it.
The effect is applied to the whole video in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L263)

>:bulb: **Note:** If you use services as [GIPHY](https://giphy.com/) you should download sticker as ```.gif``` file to the device and
then use this file to create the effect.

```Swift
let stickerEffect = effectsProvider.provideStickerEffect(duration: totalVideoDuration)
        
effectApplicator.applyOverlayEffectType(
    .gif,
    effectInfo: stickerEffect
)
        
player?.reloadComposition(shouldAutoStart: isPlaying)
```

### Create Text effect
In this example, we create Text effect that is applied to the whole video in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L248)

```Swift
let textEffect = effectsProvider.provideTextEffect(duration: totalVideoDuration)

effectApplicator.applyOverlayEffectType(
    .text,
    effectInfo: textEffect
)

player?.reloadComposition(shouldAutoStart: isPlaying)
```

### Create Blur effect
In this example, we create Blur effect that is applied to the whole video in [PlaybackManager](../VEAPISample/VEAPISample/Playback/PlaybackManager.swift#L296)
```Swift
let videoSize = player?.playerItem?.presentationSize ?? .zero
// Place blur in center of video

effectApplicator.applyOverlayEffectType(
    .blur(
        drawableFigure: .circle,
        coordinates: BlurCoordinateParams(
            center: CGPoint(x: videoSize.width / 2.0, y: videoSize.height / 2.0),
            width: videoSize.width,
            height: videoSize.height,
            radius: videoSize.width * 0.2
        )
    ),
    effectInfo: VideoEditorEffectInfo(
        id: effectsProvider.generatedEffectId,
        image: nil,
        relativeScreenPoints: nil,
        start: .zero,
        end: .zero
    )
)

player?.reloadComposition(shouldAutoStart: isPlaying)
```

### Create AR effect
>:exclamation: **Important:** [Face AR SDK](https://www.banuba.com/facear-sdk/face-filters) is required to add AR using playback API.  

Please make sure ```BanubaEffectPlayer``` is in [Podfile](../VEAPISample/Podfile#L15) and ```BanubaMaskRenderer.postprocessServicing``` is used
[VideoEditorApiModule](../VEAPISample/VEAPISample/VideoEditorApiModule.swift#L38) is in the list of Koin modules.

Normally AR effects are stored in [effects](../VEAPISample/VEAPISample/effects) folder. Any AR effect should be copied to internal storage of the device before applying.
```Swift
let maskName = "AsaiLines"
let maskEffect = effectsProvider.provideMaskEffect(withName: maskName)

// Setup Banuba Mask Renderer
// This operation can be time consuming
BanubaMaskRenderer.loadEffectPath(maskEffect.path)

editor.applyFilter(
    effectModel: maskEffect,
    start: .zero,
    end: totalVideoDuration,
    removeSameType: true
)

player?.reloadComposition(shouldAutoStart: isPlaying)
```