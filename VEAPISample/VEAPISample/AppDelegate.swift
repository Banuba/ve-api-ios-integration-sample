//
//  AppDelegate.swift
//  VEAPISample
//
//  Created by Banuba on 9.03.22.
//

import UIKit
import BanubaSdk
import BanubaEffectPlayer
import VEEffectsSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  // License token is required to start Video Editor SDK
  static let licenseToken: String = <#Enter your license token#>
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize BanubaSdkManager
    let bundleRoot = Bundle.init(for: BNBEffectPlayer.self).bundlePath
    let dirs = [bundleRoot + "/bnb-resources", Bundle.main.bundlePath + "/effects"]
    BanubaSdkManager.initialize(
      resourcePath: dirs,
      clientTokenString: AppDelegate.licenseToken,
      logLevel: .info
    )
    
    // Setup mask renderer
    BanubaMaskRenderer.postprocessServicing = MaskPostprocessingService(renderSize: Configs.resolutionConfig.current.size)
    
    return true
  }
}

