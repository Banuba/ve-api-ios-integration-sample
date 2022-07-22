//
//  PlaybackAPI.swift
//  VEAPISample
//
//  Created by Gleb Markin on 10.03.22.
//

import Foundation

import VEPlaybackSDK

class PlaybackAPI {
  // MARK: - Singleton
  static var shared = PlaybackAPI()
  
  // MARK: - Core API
  let playbackAPI: VEPlayback?
  
  init() {
    playbackAPI = VEPlayback(
      videoEditorService: CoreAPI.shared.coreAPI
    )
  }
}
