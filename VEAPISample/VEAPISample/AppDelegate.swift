//
//  AppDelegate.swift
//  VEAPISample
//
//  Created by Banuba on 9.03.22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  static let videoEditorModule = VideoEditorApiModule()
  static let licenseToken = <#Enter your license token#>
    
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppDelegate.videoEditorModule.initFaceAR()
    return true
  }
}

