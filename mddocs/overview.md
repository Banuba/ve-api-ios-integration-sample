# API Overview

- [Understand core concepts](#Understand-core-concepts)
- [Dependencies](#Dependencies)
- [Setup API](#Setup-API)

## Understand core concepts
Video Editor API includes 2 main core modules
- ```Playback API```
- ```Export API```

## Playback API
```VideoEditorPlayable``` is a core of Playback API.  ```VideoEditorPlayable``` is implemented in a similar way like other media players.
Main concepts
1. Add video playlist you want to play
2. Manage actions i.e. play, pause, change volume etc.
3. Manage effects
4. Handle events

Understanding these concepts can help you to implement any number of use cases. For example,
1. Video trimming - allow the user to trim, merge any number of video sources
2. Cover image selection - allow the user to select a video frame as a preview.
3. Video editing -  allow the user to edit video by adding various number of effects, audio

Visit [Playback API quickstart](quickstart_playback.md) to quickly integrate API into your project.

## Export API
```VEExport``` is core of Export API. With Export API you can easily make any number of video files with various effects and audio.

Supported Features
1. Multiple video in various resolutions
2. Video with any number of various effects
3. A separate audio file
4. Slideshow - video made of images
5. A GIF preview of a video

Visit [Export API quickstart](quickstart_export.md) to quickly integrate API into your project.

## Dependencies and licenses
1. [Banuba Face AR SDK](https://www.banuba.com/facear-sdk/face-filters) ```Optional```.
2. AV Kit
3. Core media
4. MetalKit
5. Accelerate

## Setup API
[CocoaPods](https://cocoapods.org) is used to get iOS Video Editor API dependencies

Learn [CocoaPods Getting Started Guide](https://guides.cocoapods.org/using/getting-started.html) if you are new in CocoaPods.

>:exclamation: Important  
It is required to have CocoaPods version ```1.11.0``` or newer.
Please check your version ```pod --version``` and upgrade.

The List of required Video Editor dependencies is in [Podfile](../VEAPISample/Podfile).

Complete the following steps to get Video Editor SDK dependencies using CocoaPods.
1. Install CocoaPods using Homebrew
   ```sh
   brew install cocoapods 
   ```
2. Initialize pods in your project folder
   ```sh
   pod init
   ```
3. Install Video Editor SDK pods
   ```sh
   pod install
   ```
4. Open ```VEAPISample.xcworkspace``` in Xcode and run the project.

Create new class [VideoEditorApiModule](../VEAPISample/VEAPISample/VideoEditorApiModule.swift) for implementing access to ```VideoEditorService``` 
and other features.
```swift
class VideoEditorApiModule {
   let editor: VideoEditorService
    
    init() {
        guard let editor = VideoEditorService(token: AppDelegate.licenseToken) else {
            fatalError("The token is invalid. Please check if token contains all characters.")
        }
        
        self.editor = editor
    }
}
```

Next, initialize ```VideoEditorApiModule```  in your [AppDelegate](../VEAPISample/VEAPISample/AppDelegate.swift#L20) class.
```VideoEditorService``` is a core class of API and SDK for initializing the product with the license token.
Instance ```editor``` is ```null``` when the license token is incorrect i.e. empty, truncated.
```diff
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
   ...
+   static let videoEditorModule = VideoEditorApiModule()
   static let licenseToken = <#Enter your license token#>

   func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
+    AppDelegate.videoEditorModule.initFaceAR()
    return true
  }
}
```
> :exclamation: Important   
> It is required to initialize Face AR [AppDelegate](../VEAPISample/VEAPISample/AppDelegate.swift#L26) if 
> your license includes [Banuba Face AR SDK](https://www.banuba.com/facear-sdk/face-filters). Otherwise, you can skip this initialization. 

### Check license state
It is highly recommended to check your license state before using API functionalities.  
Use ```VideoEditorService.getLicenseState``` method for checking the license state in your ViewController.
```Swift
let editor = AppDelegate.videoEditorModule.editor
editor.getLicenseState(completion: { [weak self] isValid in
           if isValid {
               // ✅ License is active, all good
            } else {
               // ❌ Use of Video Editor is restricted. License is revoked or expired.
            }
      })
```

## What is next?
We highly recommend to learn [Playback API quickstart](quickstart_playback.md) and [Export API quickstart](quickstart_export.md) guides to
streamline your integration process.