//
//  Gallery.swift
//  VEAPISample
//
//  Created by Gleb Markin on 11.03.22.
//

import Foundation
import Photos
import UIKit

import YPImagePicker
import BanubaUtilities
import VideoEditor

private struct Defaults {
  // MARK: - Video folder directory
  static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
  static let videosDirectory = documentsDirectory.appendingPathComponent(videosDirectoryName)
  static let videosDirectoryName = "Slideshow"
}

class GalleryViewController: UIViewController {
  
  // MARK: - Gallery picker
  private var galleryPicker: YPImagePicker?
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Usage of YPImagePicker is for demonstration purposes.
    // You could use your own implementation of gallery or another third-party library.
    setupGalleryPicker()
  }
}

// MARK: - Gallery picker helpers
extension GalleryViewController {
  private func setupGalleryPicker() {
    // Usage of YPImagePicker is for demonstration purposes.
    // You could use your own implementation of gallery or another third-party library.
    createGalleryPicker()
    setupGalleryPickerHandlers()
    
    // Present galley picker
    present(galleryPicker!, animated: false, completion: nil)
  }
  
  private func adjustPHAsset(fromAssets assets: [PHAsset]) {
    // Cast PHAsset to BanubaGalleryItem.
    let galleryItems = assets.compactMap { asset in
      // Entity from BanubaUtilities module
      BanubaGalleryItem(
        asset: asset,
        videoResolution: Configs.resolutionConfig.current
      )
    }
    
    // Setup dictionary with order to avoid multithreading issues.
    // RequestAVURLAsset could produce race condition,
    // So later we will sort our urls by order key value.
    var urls: [Int: URL] = [:]
    // Dispatch group
    let group = DispatchGroup()
    
    galleryItems.enumerated().forEach { item in
      group.enter()
      
      // Request relevant AVUrlAsset from BanubaGalleryItem entity
      item.element.requestAVURLAsset(
        // If you want to display progress use this completion
        progressHandler: nil
      ) { urlAsset, error in
        if let error = error {
          // Process error
          print(error.localizedDescription)
        } else if let urlAsset = urlAsset {
          // Add urlAsset url to following order number
          urls[item.offset] = urlAsset.url
        }
        group.leave()
      }
    }
    
    group.notify(
      queue: .global(qos: .userInteractive)
    ) { [weak self] in
      // Adjust current video urls to VideoEditorAsset entity
      self?.adjustPreparedVideoUrls(urls)
    }
  }
  
  private func adjustPreparedVideoUrls(_ urls: [Int: URL]) {
    // Reorder urls with following key order values
    let relevantUrls = urls.sorted { element, element in
      element.key > element.key
    }.compactMap { key, value in
      return value
    }
    
    // Compact urls into VideoEditorAssetTrackInfo entity
    let trackInfos = relevantUrls.compactMap { url in
      VideoEditorAssetTrackInfo(
        uuidString: UUID().uuidString,
        url: url,
        rotation: .none,
        thumbnail: nil,
        fillAspectRatioRange: VideoAspectRatio.fillAspectRatioRange,
        videoResolutionConfiguration: Configs.resolutionConfig,
        isGalleryAsset: true,
        isSlideShow: false,
        transitionEffectType: .normal
      )
    }
    
    // Create VideoEditorAsset entity
    let videoEditorAsset = VideoEditorAsset(
      tracks: trackInfos,
      videoResolutionConfiguration: Configs.resolutionConfig
    )
    
    // Setup CoreAPI with prepared VideoEditorAsset
    proccessVideoEditorAsset(
      videoEditorAsset,
      withTrackInfos: trackInfos
    )
  }
  
  private func proccessVideoEditorAsset(
    _ videoEditorAsset: VideoEditorAsset,
    withTrackInfos trackInfos: [VideoEditorAssetTrackInfo]
  ) {
    // Set current asset sequence to the CoreAPI
    CoreAPI.shared.coreAPI.setCurrentAsset(videoEditorAsset)
    
    // Interval time stamp for transform effects start and end time counting
    var startTimeStep: TimeInterval = .zero
    
    // Apply transform for different types of videos
    trackInfos.forEach { assetTrack in
      // Portrait videos should apply 90 degrees transform
      let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(assetTrack)
      // Start time setups with start interval from iteration cycle
      let startTime = assetTrack.timeRangeInGlobal.start
      // End time setups with start interval and asset duration from iteration cycle
      let endTime = assetTrack.timeRangeInGlobal.end
      // Add relevant transform to videoEditorAsset from CoreAPI
      EffectsAPI.shared.effectApplicator.addTransformEffect(
        atStartTime: startTime,
        end: endTime,
        rotation: rotation,
        isVideoFitsAspect: false
      )
      // Increase start interval from each iteration
      startTimeStep += assetTrack.urlAsset.duration.seconds
    }
    
    navigateToEditorScreen()
  }
  
  private func navigateToEditorScreen() {
    DispatchQueue.main.async { [weak self] in
      // Navigate to Editor screen
      let editorController = UIStoryboard(
        name: "Main",
        bundle: .main
      ).instantiateViewController(
        withIdentifier: "EditorViewController"
      )
      
      // Usage of YPImagePicker is for demonstration purposes.
      // You could use your own implementation of gallery or another third-party library.
      self?.galleryPicker?.dismiss(animated: false) {
        self?.galleryPicker = nil
        self?.navigationController?.pushViewController(
          editorController,
          animated: true
        )
      }
    }
  }
  
  private func setupGalleryPickerHandlers() {
    // Handler of YPImagePicker
    galleryPicker?.didFinishPicking { [weak self] items, cancelled in
      guard !cancelled else {
        // Pop view controller if cancelled
        self?.galleryPicker?.dismiss(animated: false) {
          self?.galleryPicker = nil
          self?.navigationController?.popViewController(animated: true)
        }
        return
      }
      
      // Compact YP items into PHAsset set
      let assets: [PHAsset] = items.compactMap { item in
        switch item {
        case .video(v: let videoItem):
          return videoItem.asset
        default:
          return nil
        }
      }
      
      // Adjust PHAssets into BanubaGalleryItems
      self?.adjustPHAsset(fromAssets: assets)
    }
  }
  
  private func createGalleryPicker() {
    // Usage of YPImagePicker is for demonstration purposes.
    // You could use your own implementation of gallery or another third-party library.
    var config = YPImagePickerConfiguration()
    
    config.video.libraryTimeLimit = 600.0
    config.video.minimumTimeLimit = 0.3
    
    config.screens = [.library]
    config.showsVideoTrimmer = false
    
    config.library.mediaType = .video
    config.library.defaultMultipleSelection = true
    config.library.maxNumberOfItems = 10
    
    galleryPicker = YPImagePicker(configuration: config)
  }
}

