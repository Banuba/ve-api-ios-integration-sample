//
//  AppDelegate.swift
//  VEAPISample
//
//  Created by Banuba on 9.03.22.
//

import UIKit
import BanubaSdk
import BanubaEffectPlayer
import BanubaUtilities
import VEEffectsSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  
  static let videoEditorModule = VideoEditorModule()
  static let licenseToken = <#Enter your license token#>
    
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Used ???
    // Initialize BanubaSdkManager
    let bundleRoot = Bundle.init(for: BNBEffectPlayer.self).bundlePath
    let dirs = [bundleRoot + "/bnb-resources", Bundle.main.bundlePath + "/effects"]
    BanubaSdkManager.initialize(
      resourcePath: dirs,
      clientTokenString: AppDelegate.licenseToken,
      logLevel: .info
    )
    
    AppDelegate.videoEditorModule.setupMaskRenderer()
    return true
  }
}

