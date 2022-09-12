//
//  VideoURL+Size.swift
//  VEAPISample
//
//  Created by Gleb Markin on 11.03.22.
//

import Foundation
import AVFoundation
import UIKit

extension URL {
    var videoSize: CGSize? {
        let track = AVAsset(url: self).tracks(withMediaType: .video).first
        guard let track = track else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
}
