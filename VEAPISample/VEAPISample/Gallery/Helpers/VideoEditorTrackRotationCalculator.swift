//
//  VideoEditorTrackRotationCalculator.swift
//  VEAPISample
//
//  Created by Ruslan Filistovich on 1.08.22.
//

import Foundation
import VideoEditor

/// Allows you to calculate rotation with required VideoEditorAssetTrackInfo
public class VideoEditorTrackRotationCalculator {
  /// Allows you to calculate rotation with required VideoEditorAssetTrackInfo
  /// - Parameters:
  ///  - track: Video part track information
  public static func getTrackRotation(_ track: VideoEditorAssetTrackInfo) -> AssetRotation {
    guard let preferredTransform = track.urlAsset.tracks(withMediaType: .video).first?.preferredTransform,
          preferredTransform != .identity else {
      return track.rotation
    }
    
    var trackRotationAngle = atan2(preferredTransform.b, preferredTransform.a)
    
    // Adjust angle to right turn
    // Info: if angle - pi/2 we should rotate to (2*pi - angle) to have original view.
    // In other cases enough to abs(angle)
    if trackRotationAngle >= -(.pi / 2.0) && trackRotationAngle < .zero {
      trackRotationAngle = 2.0 * .pi + trackRotationAngle
    } else if trackRotationAngle < .zero {
      trackRotationAngle = abs(trackRotationAngle)
    }
    
    let angle = track.rotation.angle + trackRotationAngle
    let resultRotation = AssetRotation(withAngle: angle)
    
    return resultRotation ?? .none
  }
}
