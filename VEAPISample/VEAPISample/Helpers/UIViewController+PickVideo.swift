//
//  UIViewController+PickerMedia.swift
//  VEAPISample
//
//  Created by Andrey Sak on 16.03.23.
//

import UIKit
import AVKit
import YPImagePicker

extension UIViewController {
    /// Present video picker and returns an array of selected video in completion block
    func pickVideo(completion: ((_ videoUrls: [URL]?) -> Void)?) {
        // Usage of YPImagePicker is for demonstration purposes.
        // You could use your own implementation of gallery or another third-party library.
        var config = YPImagePickerConfiguration()
        
        config.video.libraryTimeLimit = 600.0
        config.video.minimumTimeLimit = 0.3
        config.video.compression = AVAssetExportPresetPassthrough
        
        config.screens = [.library]
        config.showsVideoTrimmer = false
        
        config.library.mediaType = .video
        config.library.defaultMultipleSelection = true
        config.library.maxNumberOfItems = 10
        
        let galleryPicker = YPImagePicker(configuration: config)
        
        // Handler of YPImagePicker
        galleryPicker.didFinishPicking { items, cancelled in
            guard !cancelled else {
                galleryPicker.dismiss(animated: true) {
                    completion?(nil)
                }
                return
            }
            
            // Compact YP items into PHAsset set
            let videoUrls: [URL] = items.compactMap { item in
                switch item {
                case .video(v: let videoItem):
                    return videoItem.url
                default:
                    return nil
                }
            }
            
            galleryPicker.dismiss(animated: true) {
                completion?(videoUrls)
            }
        }
        
        present(galleryPicker, animated: true)
    }
}
