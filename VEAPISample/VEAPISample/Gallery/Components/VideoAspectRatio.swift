//
//  VideoAspectRatio.swift
//  VEAPISample
//
//  Created by Banuba on 11.03.22.
//

import Foundation
import UIKit

public struct VideoAspectRatio {
  private static let minFillSizeParts: CGSize = CGSize(width: 8, height: 16)
  private static let maxFillSizeParts: CGSize = CGSize(width: 10, height: 16)
  
  /// Minimum fitted aspect ratio
  public static var minFillAspectRatio: CGFloat {
    return minFillSizeParts.width / minFillSizeParts.height
  }
  
  /// Maximum fitted aspect ratio
  public static var maxFillAspectRatio: CGFloat {
    return maxFillSizeParts.width / maxFillSizeParts.height
  }
  
  /// Filling fitted aspect ratio
  public static var fillAspectRatioRange: ClosedRange<CGFloat> {
    return minFillAspectRatio...maxFillAspectRatio
  }
}
