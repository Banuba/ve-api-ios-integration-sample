//
//  Configs.swift
//  VEAPISample
//
//  Created by Banuba on 10.03.22.
//

import Foundation

import BanubaUtilities

struct Configs {
  static var resolutionConfig: VideoResolutionConfiguration {
    return VideoResolutionConfiguration(
      default: .hd1920x1080,
      resolutions: [
        // M2, 8/16 GB
        .iPadPro12Inch6: .hd1920x1080,
        .iPadPro11Inch4: .hd1920x1080,
        
        // A16, 6 GB
        .iPhone14Pro: .hd1920x1080,
        .iPhone14ProMax: .hd1920x1080,
        
        // M1, 8/16 GB
        .iPadPro12Inch5: .hd1920x1080,
        .iPadPro11Inch3: .hd1920x1080,
        .iPadAir5: .hd1920x1080,
        
        // A15, 6 GB
        .iPhone14: .hd1920x1080,
        .iPhone14Plus: .hd1920x1080,
        .iPhone13Pro: .hd1920x1080,
        .iPhone13ProMax: .hd1920x1080,
        
        // A15, 4 GB
        .iPhone13: .hd1920x1080,
        .iPhone13Mini: .hd1920x1080,
        .iPhoneSE3: .hd1920x1080,
        .iPadMini6: .hd1920x1080,
        
        // A14, 6 GB
        .iPhone12Pro: .hd1920x1080,
        .iPhone12ProMax: .hd1920x1080,
        
        // A14, 4 GB
        .iPhone12: .hd1920x1080,
        .iPhone12Mini: .hd1920x1080,
        .iPad10: .hd1920x1080,
        .iPadAir4: .hd1920x1080,
        
        // A13, 4 GB
        .iPhone11: .hd1920x1080,
        .iPhone11Pro: .hd1920x1080,
        .iPhone11ProMax: .hd1920x1080,
        
        // A13, 3 GB
        .iPad9: .hd1920x1080,
        .iPhoneSE2: .hd1920x1080,
        
        // A12Z, 6 GB
        .iPadPro12Inch4: .hd1920x1080,
        .iPadPro11Inch2: .hd1920x1080,
        
        // A12X, 4 GB
        .iPadPro12Inch3: .hd1920x1080,
        .iPadPro11Inch: .hd1920x1080,
        
        // A12, 4 GB
        .iPhoneXS: .hd1920x1080,
        .iPhoneXSMax: .hd1920x1080,
        
        // A12, 3 GB
        .iPhoneXR: .hd1920x1080,
        .iPadAir3: .hd1920x1080,
        .iPadMini5: .hd1920x1080,
        .iPad8: .hd1920x1080,
        
        // A11, 3 GB
        .iPhone8Plus: .hd1920x1080,
        .iPhoneX: .hd1920x1080,
        
        // A11, 2 GB
        .iPhone8: .hd1920x1080,
        
        // A10X, 4 GB
        .iPadPro12Inch2: .hd1920x1080,
        .iPadPro10Inch: .hd1920x1080,
        
        // A10, 3 GB
        .iPhone7Plus: .hd1920x1080,
        .iPad7: .hd1920x1080,
        
        // A10, 2 GB
        .iPhone7: .hd1920x1080,
        .iPad6: .hd1920x1080,
        .iPodTouch7: .hd1920x1080,
        
        // A9X, 4 GB RAM
        .iPadPro12Inch: .hd1920x1080,
        
        // A9X, 2 GB RAM
        .iPadPro9Inch: .hd1920x1080,
        
        // A9, 2 GB RAM
        .iPhone6s: .hd1280x720,
        .iPhone6sPlus: .hd1280x720,
        .iPhoneSE: .hd1280x720,
        .iPad5: .hd1280x720,
        
        // A8X, 2 GB RAM
        .iPadAir2: .hd1280x720,
        
        // A8, 2 GB RAM
        .iPadMini4: .hd1280x720,
        
        // A8, 1 GB RAM
        .iPhone6: .hd1280x720,
        .iPhone6Plus: .hd1280x720,
        .iPodTouch6: .hd1280x720,
        
        // A7, 1 GB RAM
        .iPhone5s: .hd1280x720,
        .iPadMini2: .hd1280x720,
        .iPadMini3: .hd1280x720,
        .iPadAir: .hd1280x720
      ],
      thumbnailHeights: [
        .iPhone5s: 200.0,
        .iPhone6: 80.0,
        .iPhone6s: 200.0,
        .iPhone6Plus: 80.0,
        .iPhone6sPlus: 200.0,
        .iPhoneSE: 200.0,
      ],
      defaultThumbnailHeight: 400.0
    )
  }
}
