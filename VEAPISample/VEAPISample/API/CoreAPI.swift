//
//  VideoEditorAPI.swift
//  VEAPISample
//
//  Created by Banuba on 10.03.22.
//

import Foundation

import VideoEditor
import VEEffectsSDK

class CoreAPI {
  // MARK: - Singleton
  static var shared = CoreAPI()
  
  // MARK: - Core API
  let coreAPI: VideoEditorService
  
  init() {
    guard let coreAPI = VideoEditorService(token: AppDelegate.licenseToken) else {
      fatalError("The token is invalid. Please check if token contains all characters.")
    }
    self.coreAPI = coreAPI
  }
}
