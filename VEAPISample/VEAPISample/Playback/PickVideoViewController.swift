//
//  PickVideoViewController.swift
//  VEAPISample
//
//  Created by Banuba on 2.03.23.
//

import UIKit
import YPImagePicker
import AVFoundation

import VideoEditor

class PickVideoViewController: UIViewController {
  
  @IBOutlet weak var invalidTokenLabel: UILabel!
  
  private var editor: VideoEditorService!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupEditorService()
  }
  
  private func setupEditorService() {
    guard let editor = VideoEditorService(token: AppDelegate.licenseToken) else {
      fatalError("The token is invalid. Please check if token contains all characters.")
    }
    
    self.editor = editor
  }
  
  @IBAction func pickVideoAction(_ sender: UIButton) {
    checkLicense {
      self.presentMediaPicker()
    }
  }
  
  @IBAction func backAction(_ sender: Any) {
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
        self?.presentPlaybackViewController(with: videoUrls)
      }
    }
    
    present(galleryPicker, animated: true)
  }
  
  func presentPlaybackViewController(with videoUrls: [URL]) {
    performSegue(
      withIdentifier: "showVideoEditorPlayback",
      sender: videoUrls
    )
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard
      segue.identifier == "showVideoEditorPlayback",
      let videoUrls = sender as? [URL],
        let playbackVC = segue.destination as? PlaybackViewController
    else {
      super.prepare(for: segue, sender: sender)
      return
    }
    // Pass parameters to playback view controller
    playbackVC.videoUrls = videoUrls
    playbackVC.editor = editor
  }
}

// MARK: - Private
extension PickVideoViewController {
  private func checkLicense(completion: @escaping () -> Void) {
    editor.getLicenseState(completion: { [weak self] isValid in
      self?.invalidTokenLabel.isHidden = isValid
      if isValid {
        completion()
      }
    })
  }
}
