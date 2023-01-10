//
//  PlaybackViewController.swift
//  VEAPISample
//
//  Created by Banuba on 28.12.22.
//

import UIKit
import YPImagePicker
import AVFoundation

// Banuba Modules
import VideoEditor
import VEPlaybackSDK
import VEEffectsSDK
import BanubaUtilities

class PlaybackViewController: UIViewController {
  // MARK: - Player container
  @IBOutlet weak var playerContainerView: UIView!
  @IBOutlet weak var openVideoButton: UIButton!

  @IBOutlet weak var invalidTokenLabel: UILabel!
        
  // MARK: - VideoPlayableView
  var playableView: VideoPlayableView?

  // MARK: - AppStateObserver
  var appStateObserver: AppStateObserver?
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    setupAppStateHandler()
  }
}

// MARK: - Playback Helpers
extension PlaybackViewController {
  func setupPlaybackView() {
    // Check if Playable View already exist
    if let currentView = playableView {
      currentView.removeFromSuperview()
    }
    // Get playable view
    guard let view = PlaybackAPI.shared.playbackAPI?.getPlayableView(delegate: self) else {
      return
    }
    playableView = view
    // Setup view frame
    view.frame = playerContainerView.bounds
    playerContainerView.addSubview(view)
    
    self.view.layoutIfNeeded()
    // Start playing
    playableView?.videoEditorPlayer?.startPlay(loop: true, fixedSpeed: false)
  }
  
  func setupAppStateHandler() {
    appStateObserver = AppStateObserver(delegate: self)
  }
}

// MARK: - App state observer
extension PlaybackViewController: AppStateObserverDelegate {
  func applicationWillResignActive(_ appStateObserver: AppStateObserver) {
    playableView?.videoEditorPlayer?.stopPlay()
  }
  func applicationDidBecomeActive(_ appStateObserver: AppStateObserver) {
    playableView?.videoEditorPlayer?.startPlay(loop: true, fixedSpeed: false)
  }
}

// MARK: - Action
extension PlaybackViewController {
  @IBAction func openVideoAction(_ sender: Any) {
    checkLicense {
      self.presentMediaPicker()
    }
  }
  
  @IBAction func backAction(_ sender: Any) {
    playableView?.videoEditorPlayer?.pausePlay()
    navigationController?.dismiss(animated: true)
  }
  
  private func presentMediaPicker() {
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
    galleryPicker.didFinishPicking { [weak self] items, cancelled in
      guard !cancelled else {
        galleryPicker.dismiss(animated: true)
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
        self?.processVideo(videoUrls: videoUrls)
        self?.setupPlaybackView()
      }
    }
    
    present(galleryPicker, animated: true)
  }
}

// MARK: - Private
extension PlaybackViewController {
  private func checkLicense(completion: @escaping () -> Void) {
    CoreAPI.shared.coreAPI.getLicenseState(completion: { [weak self] isValid in
      self?.invalidTokenLabel.isHidden = isValid
      if isValid {
        completion()
      }
    })
  }
}
