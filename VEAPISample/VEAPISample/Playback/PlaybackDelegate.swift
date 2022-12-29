//
//  PlaybackDelegate.swift
//  VEAPISample
//
//  Created by Banuba on 29.12.22.
//

import Foundation
import AVFoundation
import VEPlaybackSDK
import BanubaUtilities

// MARK: - VideoEditorPlayerDelegate
extension PlaybackViewController: VideoEditorPlayerDelegate {
  func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime) {
    print(time.seconds)
  }
  
  func playerDidEndPlaying(_ player: VideoEditorPlayable) {
    print("Did end playing")
  }
}

