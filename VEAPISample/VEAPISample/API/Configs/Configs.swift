//
//  Configs.swift
//  VEAPISample
//
//  Created by Gleb Markin on 10.03.22.
//

import Foundation

import BanubaUtilities

struct Configs {
  static var resolutionConfig: VideoResolutionConfiguration {
    return VideoResolutionConfiguration(
      default: .hd1920x1080,
      resolutions: [
        .iPadAir1 : .hd1280x720,
        .iPadAir2 : .hd1280x720,
        .iPadAir3 : .hd1280x720,
        .iPadAir4 : .hd1280x720,
        
        .iPad2 : .hd1280x720,
        .iPad3 : .hd1280x720,
        .iPad4 : .hd1280x720,
        .iPad5 : .hd1280x720,
        .iPad6 : .hd1280x720,
        .iPad7 : .hd1280x720,
        .iPad8 : .hd1280x720,
        
        .iPadMini1 : .hd1280x720,
        .iPadMini2 : .hd1280x720,
        .iPadMini3 : .hd1280x720,
        .iPadMini4 : .hd1280x720,
        .iPadMini5 : .hd1280x720,
        
        .iPadPro9_7     : .hd1280x720,
        .iPadPro10_5    : .hd1280x720,
        .iPadPro11      : .hd1280x720,
        .iPadPro2_11    : .hd1280x720,
        .iPadPro3_11    : .hd1280x720,
        .iPadPro12_9    : .hd1280x720,
        .iPadPro2_12_9  : .hd1280x720,
        .iPadPro3_12_9  : .hd1280x720,
        .iPadPro4_12_9  : .hd1280x720,
        .iPadPro5_12_9  : .hd1280x720,
        
        .iPhone5S : .hd1280x720,
        .iPhone6: .default854x480,
        .iPhone6S: .hd1280x720,
        .iPhone6plus: .default854x480,
        .iPhone6Splus: .hd1280x720,
        .iPhoneSE: .hd1280x720,
        .iPhone5 : .hd1280x720,
      ],
      thumbnailHeights: [
        .iPhone5S: 200.0,
        .iPhone6: 80.0,
        .iPhone6S: 200.0,
        .iPhone6plus: 80.0,
        .iPhone6Splus: 200.0,
        .iPhoneSE: 200.0,
      ],
      defaultThumbnailHeight: 400.0
    )
  }
}
