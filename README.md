[![](https://www.banuba.com/hubfs/Banuba_November2018/Images/Banuba%20SDK.png)](https://www.banuba.com/video-editor-sdk)

# Video Editor SDK. VE API Integration sample for iOS.

- [API Reference](#API-Reference)
    + [FAR Camera](#FAR-Camera)
    + [Playback API](#Playback-API)
    + [Export API](#Export-API)
    + [Effects API](#Effects-API)
    + [Core API](#Core-API)
- [Requirements](#Requirements)
- [Token](#Token)
- [Getting Started](#Getting-Started)
    + [CocoaPods](#CocoaPods)


Sample is a basic integration of VE API. Navigation flow consists of camera, editor, gallery screens with Facade API entities, funcs implementations. Sample architecture is MVC and singleton API services. This is necessary so that there are no third-party difficulties when reading the code.

See how to use basic screen settings with the API Entites. All of API referencies you could find out here:

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

## Requirements
This is what you need to run the AI Video Editor SDK

- iPhone devices 6+
- Swift 5+
- Xcode 13+
- iOS 12.0+
Unfortunately, It isn't optimized for iPads.

## Starting a free trial

You should start with getting a trial token. It will grant you **14 days** to freely play around with the AI Video Editor SDK and test its entire functionality the way you see fit.

There is nothing complicated about it - [contact us](https://www.banuba.com/video-editor-sdk) or send an email to sales@banuba.com and we will send it to you. We can also send you a sample app so you can see how it works “under the hood”.

## Token 
We offer а free 14-days trial for you could thoroughly test and assess Video Editor SDK functionality in your app. To get access to your trial, please, get in touch with us by [filling a form](https://www.banuba.com/video-editor-sdk) on our website. Our sales managers will send you the trial token.

Video Editor token should be put [here](https://github.com/Banuba/ve-api-ios-integration-sample/blob/6459c63eb529042601a7e61c474d7f83badc27d6/VEAPISample/VEAPISample/AppDelegate.swift#L12).

## Getting Started
### CocoaPods

In the sample project there is a division into folders, such as `API`, `Camera`, `Gallery`, `Editor`: all the functionality inherent in the API integration is in the ['API'](https://github.com/Banuba/ve-api-ios-integration-sample/tree/master/VEAPISample/VEAPISample/API) folder, API entities dilivery architecture is Singleton to simple usage with the sample MVC arch. Screen information to support the functionality of the sample is in the ['Camera'](https://github.com/Banuba/ve-api-ios-integration-sample/tree/master/VEAPISample/VEAPISample/Camera), ['Gallery'](https://github.com/Banuba/ve-api-ios-integration-sample/tree/master/VEAPISample/VEAPISample/Gallery), ['Editor'](https://github.com/Banuba/ve-api-ios-integration-sample/tree/master/VEAPISample/VEAPISample/Editor) folders.

The easiest way to integrate the Video Editor SDK in your mobile app is through [CocoaPods](https://cocoapods.org). If you haven’t used this dependency manager before, see the [Getting Started Guide](https://guides.cocoapods.org/using/getting-started.html).

Important: Make sure that you have CocoaPods version >= 1.9.0 installed. Check your CocoaPods version using this command [pod --version]

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
