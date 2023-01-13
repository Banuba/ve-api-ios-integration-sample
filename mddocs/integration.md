## Video Editor API Integration on iOS

### Add dependencies
The easiest way to integrate the Video Editor SDK in your mobile app is through [CocoaPods](https://cocoapods.org). If you haven’t used this dependency manager before, see the [Getting Started Guide](https://guides.cocoapods.org/using/getting-started.html).

Important: Make sure that you have CocoaPods version >= 1.11.0 installed. Check your CocoaPods version using this command [pod --version]

Please, refer to the example of [Podfile](https://github.com/Banuba/ve-api-ios-integration-sample/blob/master/VEAPISample/Podfile) lines which you need to add.

1. Make sure to have CocoaPods installed, e.g. via Homebrew:
   ```sh
   brew install cocoapods 
   ```
2. Initialize pods in your project folder (if you didn't do it before).
   ```sh
   pod init
   ```
3. Install the Video Editor SDK for the provided Xcode workspace with:
   ```sh
   pod install
   ```
4. Open Example.xcworkspace with Xcode and run the project.  

Sample is a basic integration of VE API. Navigation flow consists of camera, editor, gallery screens with Facade API entities, funcs implementations. Sample architecture is MVC and singleton API services. This is necessary so that there are no third-party difficulties when reading the code.

## FAR Camera
Camera is representation of BanubaSDK and BanubaEffectPlayer. All relevant information and docs is [here](https://docs.banuba.com/face-ar-sdk-v1/ios/ios_overview).

## Playback API
`VEPlaybackSDK` allows you to display already setuped video composition from [Core API](https://github.com/Banuba/VideoEditor-iOS) and optionally edited with [Effects API](https://github.com/Banuba/BanubaVideoEditorEffectsSDK-iOS). So [Core API](https://github.com/Banuba/VideoEditor-iOS) is requires usage for `VEPlaybackSDK`.

[API Reference](https://github.com/Banuba/VEPlaybackSDK-iOS)

## Export API
`VEExportSDK` allows you to export video composition which already setuped in [Core API](https://github.com/Banuba/VideoEditor-iOS) and optionally edited with [Effects API](https://github.com/Banuba/BanubaVideoEditorEffectsSDK-iOS). So [Core API](https://github.com/Banuba/VideoEditor-iOS) is requires usage for `VEExportSDK`.

[API Reference](https://github.com/Banuba/VEExportSDK-iOS)

## Effects API
`VEEffectsSDK` allows you to edit video composition which already setuped in [Core API](https://github.com/Banuba/VideoEditor-iOS). So [Core API](https://github.com/Banuba/VideoEditor-iOS) is requires usage for `VEEffectsSDK`.

[API Reference](https://github.com/Banuba/BanubaVideoEditorEffectsSDK-iOS)

## Core API
`VideoEditor` is a core module for interaction between playback modules, export, etc. All transformations with effects, sounds, time, trimming take place inside this module. In order to use exporting, applying effects, or getting a player, first you need to use the essence of the `VideoEditorService` entity and add the necessary video segments or assets to it.

[API Reference](https://github.com/Banuba/VideoEditor-iOS)

