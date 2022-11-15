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
    let watermarkApplicator = WatermarkApplicator()
    coreAPI = VideoEditorService(
      token: token,
      watermarkApplicator: watermarkApplicator
    )
  }
}
