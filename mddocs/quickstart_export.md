# Quickstart Export API

- [Overview](#Overview)
- [Prepare export flow](#Prepare-export-flow)
- [Handle export result](#Handle-export-result)
- [Prepare effects](#Prepare-effects)

## Overview
This guide is aimed to help you quickly to integrate Export API into your project.
You will learn how to export a number of media files i.e. video, audio, gif with various effects and in various resolutions.

Export API produces video as ```.mp4``` file.
 
Export is a very heavy CPU and GPU intensive computational task.
Execution time depends on
1. Video duration - the longer video the longer execution time.
2. Number of video and audio sources - the more sources the longer execution time.
3. Number of effects and their usage in video - the more effects and their usage the longer execution time.
4. Number of exported video - the more video and audio you want to export the longer execution time it takes.
5. Device hardware - the most powerful devices can execute export much quicker.

Export supports ```Foreground``` mode where the user has to wait on progress screen until processing is done.

Visit [export guide](https://github.com/Banuba/ve-sdk-ios-integration-sample/blob/main/mdDocs/guide_export.md) to learn more
about export in Video Editor SDK.

## Prepare export flow

```VideoEditorService```, ```VEExport``` and ```ExportVideoInfo``` are the main classes of export execution.
Video content should be set to ```VideoEditorService```. Instance of ```VEExport``` depends on ```VideoEditorService``` 
thus ```VEExport``` knows about video content that should be processed in export. ```ExportVideoInfo``` includes 
export capability params as video resolution, video codec, etc.

First, create instance of ```VEExport```
```Swift
let exportSDK = VEExport(videoEditorService: videoEditorService)
``` 
where ```videoEditorService``` can be accessed from [VideoEditorApiModule](../VEAPISample/VEAPISample/VideoEditorApiModule.swift)

Next, add video content for export
```Swift
    let videoContent: [URL] = ...
    // Create videoSequence of video by provided video urls

    let videoSequence = createVideoSequence(with: videoUrls)
    self.videoSequence = videoSequence
        
    let videoEditorAsset = VideoEditorAsset(
          sequence: videoSequence,
          isGalleryAssets: true,
          isSlideShow: false,
          videoResolutionConfiguration: videoResolutionConfiguration
    )
        
    // Set current video asset to video editor service
    editor.setCurrentAsset(videoEditorAsset)
``` 

Finally, start export using ```VEExport.exportVideo```.
In this sample, video with 1080p resolution, watermark and H265 codec will be exported.
```Swift
// Prepare video effects
 prepareEffects()
        
let filename = "tmp.mov"
// Prepare result video url
let resultVideoUrl = FileManager.default.temporaryDirectory.appendingPathComponent("filename")
if FileManager.default.fileExists(atPath: resultVideoUrl.path) {
    try? FileManager.default.removeItem(at: resultVideoUrl)
}
        
// Export settings
let exportVideoInfo = ExportVideoInfo(
    resolution: .fullHd1080,
    useHEVCCodecIfPossible: true
)
        
// Prepare watermark
let watermark = prepareWatermark(image: UIImage(named: "banuba_watermark")!)
        
exportSDK.exportVideo(
    to: resultVideoUrl,
    using: exportVideoInfo,
    watermarkFilterModel: watermark,
    exportProgress: { progress in progressCallback?(Float(progress)) },
    completion: { success, error in completion?(resultVideoUrl, success, error) }
)
```

Please [check out](../VEAPISample/VEAPISample/Export/ExportManager.swift#L74) sample export implementation

## Handle export result
Method ```VEExport.exportVideo()``` allows either start export and track the result.  
Provide
1. ```resultVideoUrl``` - use it to access to exported video when export finishes successfully
2. ```exportProgress``` - callback that gets called when export progress changes. Values are 0.0-1.0
3. ```completion```- callback that gets called when export finishes successfully or with an error.

## Prepare effects
You have at least 2 options how to prepare video effects and audio tracks for export:
1. The user adds video effects and audio tracks on the screens implemented using Playback API and next you pass these effects to export.
2. You prepare video effects and audio tracks in isolation and pass it to export.

Follow [Manage effects](quickstart_playback.md#Manage-effects) guide where we fully explained how to create effects for playback.
The same approach works for export as well.
