//
//  AppDelegate.swift
//  VEAPISample
//
//  Created by Gleb Markin on 9.03.22.
//

import UIKit
import BanubaSdk
import BanubaEffectPlayer

let token = <#Place your token here#>

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize BanubaSdkManager
    let bundleRoot = Bundle.init(for: BNBEffectPlayer.self).bundlePath
    let dirs = [bundleRoot + "/bnb-resources", Bundle.main.bundlePath + "/effects"]
    BanubaSdkManager.initialize(
      resourcePath: dirs,
      clientTokenString: token,
      logLevel: .info
    )
    
    return true
  }
}

