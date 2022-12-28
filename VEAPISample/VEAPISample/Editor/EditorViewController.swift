//
//  EditorViewController.swift
//  VEAPISample
//
//  Created by Banuba on 10.03.22.
//

import Foundation
import AVFoundation
import UIKit

import VEPlaybackSDK
import VideoEditor
import VEEffectsSDK
import VEExportSDK
import BanubaUtilities

class EditorViewController: UIViewController {
  // MARK: - Player container
  @IBOutlet weak var playerContainerView: UIView!
  
  // MARK: - Effect buttons
  @IBOutlet weak var colorButton: UIButton!
  @IBOutlet weak var speedButton: UIButton!
  @IBOutlet weak var musicButton: UIButton!
  @IBOutlet weak var effectButton: UIButton!
  @IBOutlet weak var textButton: UIButton!
  @IBOutlet weak var gifButton: UIButton!
  
  // MARK: - Activity indicator
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  // MARK: - Navigation button
  @IBOutlet weak var nextButton: UIButton!
  
  // MARK: - Music volume controls
  @IBOutlet weak var musicTrackControlsTopConstraint: NSLayoutConstraint!
  @IBOutlet weak var videoVolumeSlider: UISlider!
  @IBOutlet weak var trackVolumeSlider: UISlider!
  
  // MARK: - Music track id
  var trackId: CMPersistentTrackID = .zero
  var trackUrl: URL?
  let originalVideoAudioTrackId: CMPersistentTrackID = 2
  
  // MARK: - VideoPlayableView
  var playableView: VideoPlayableView?
  
  private var exportEffectProvider: ExportEffectProvider = ExportEffectProvider(totalVideoDuration: .zero)
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Setup playback view with container frame size
    setupPlaybackView()
    // Setup navigation buttons
    setupNavigationButtons()
    
    let totalDuration = CoreAPI.shared.coreAPI.videoAsset?.composition.duration ?? .zero
    exportEffectProvider = ExportEffectProvider(totalVideoDuration: totalDuration)
  }
}

// MARK: - Navigation helpers
extension EditorViewController {
  @IBAction func backButtonDidTap(_ sender: UIButton) {
    // Back to Camera screen
    navigationController?.popToRootViewController(animated: true)
    // Remove asset sequence from CoreAPI
    CoreAPI.shared.coreAPI.setCurrentAsset(nil)
  }
  
  private func setupNavigationButtons() {
    // Corner radius
    nextButton.layer.cornerRadius = 10.0
  }
}

// MARK: - Playback Helpers
extension EditorViewController {
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
    view.frame = playerContainerView.frame
    playerContainerView.addSubview(view)
    
    self.view.layoutIfNeeded()
    // Start playing
    playableView?.videoEditorPlayer?.startPlay(loop: true, fixedSpeed: false)
  }
}

// MARK: - Export helpers
extension EditorViewController {
  private func exportVideo() {
    playableView?.videoEditorPlayer?.stopPlay()
    // Setup result video url
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("video.mp4")
    if FileManager.default.fileExists(atPath: fileURL.path) {
      // Remove if exist
      try? FileManager.default.removeItem(at: fileURL)
    }
    
    // Create watermark applicator
    let watermarkApplicator = WatermarkApplicator()
    // Watermark configuration
    let watermarkConfiguration = WatermarkConfiguration(
      watermark: ImageConfiguration(imageName: "banuba_logo"),
      size: CGSize(width: 204, height: 52),
      sharedOffset: 20,
      position: .rightBottom
    )
    
    // Adjust watermark config to video editor filter model
    let watermarkModel = watermarkApplicator.adjustWatermarkEffect(
      configuration: watermarkConfiguration,
      videoSize: Configs.resolutionConfig.current.size
    )
    
    // Export settings
    let exportInfo = ExportVideoInfoFactory.assetExportSettings(
      resolution: Configs.resolutionConfig.current,
      useHEVCCodecIfPossible: true
    )
    
    // Start activity indicator
    activityIndicator.startAnimating()
    
    // Export video with set of params
    let exportSDK = VEExport(videoEditorService: CoreAPI.shared.coreAPI)
    
    exportSDK?.exportVideo(
      to: fileURL,
      using: exportInfo,
      watermarkFilterModel: watermarkModel,
      exportProgress: { progress in
        print("export video progress: \(progress)")
      }, completion: { [weak self] isSuccess, error in
        // Return to main thread
        DispatchQueue.main.async {
          self?.playableView?.videoEditorPlayer?.startPlay(loop: true, fixedSpeed: false)
          // Stop activity indicator
          self?.activityIndicator.stopAnimating()
        }
        if let error = error {
          // Proccess error
          print(error.localizedDescription)
        } else {
          self?.saveVideoToGallery(fileURL: fileURL.relativePath)
        }
      })
  }
  
  private func saveVideoToGallery(fileURL: String) {
    // Save video to gallery
    guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fileURL) else {
      return
    }
    UISaveVideoAtPathToSavedPhotosAlbum(fileURL, nil, nil, nil)
  }
}

// MARK: - Effect applicator
extension EditorViewController {
  
  func applyMusicEffect() {
    // Get relevant instance of video asset
    let videoAsset = CoreAPI.shared.coreAPI.videoAsset
    
    // Music URL
    guard let url = Bundle.main.url(forResource: "Music/long_music", withExtension: "wav") else {
      return
    }
    
    // Get duration time from video asset duration
    let durationTime = videoAsset?.composition.duration ?? .invalid
    let trackTimeRange = CMTimeRange(
      start: .zero,
      duration: durationTime
    )
    
    // Track time range
    let timeRange = MediaTrackTimeRange(
      startTime: .zero,
      playingTimeRange: trackTimeRange
    )
    
    // Store id to essence of removing existing track
    let id = CMPersistentTrackID.random(in: 100...CMPersistentTrackID.max)
    trackUrl = url
    trackId = id
    
    // Track instance
    let track = MediaTrack(
      id: id,
      url: url,
      timeRange: timeRange,
      isEditable: true,
      title: "Track"
    )
    // Add newest music track
    videoAsset?.addMusicTrack(track)
    
    // Get new instance of player to playback music track
    reloadPlayer()
  }
  
  private func reloadPlayer() {
    // Get new instance of player to playback music track
    guard let player = PlaybackAPI.shared.playbackAPI?.getPlayer(
      forExternalAsset: nil,
      delegate: self
    ) else {
      return
    }
    
    // Setup new player
    playableView?.setPlayer(player, isThumbnailNeeded: false)
    // Reload preview and start loop playing
    playableView?.videoEditorPlayer?.reloadPreview(shouldAutoStart: true)
    playableView?.videoEditorPlayer?.startPlay(loop: true, fixedSpeed: false)
  }
}

// MARK: - Actions
extension EditorViewController {
  @IBAction func nextButtonDidTap(_ sender: UIButton) {
    // Export existing video
    exportVideo()
  }
  
  @IBAction func colorButtonDidTap(_ sender: UIButton) {
    // Change button state
    sender.isSelected = !sender.isSelected
    guard sender.isSelected else {
      // Undo color effect
      let _ = CoreAPI.shared.coreAPI.undoLast(type: .color)
      return
    }
    
    let exportEffect = exportEffectProvider.provideColorExportEffect()
    
    guard let lutUrl = exportEffect.additionalInfo[ExportEffectAdditionalInfoKey.url] as? URL,
          let name = exportEffect.additionalInfo[ExportEffectAdditionalInfoKey.name] as? String else {
      return
    }
    EffectsAPI.shared.effectApplicator.applyColorEffect(
      name: name,
      lutUrl: lutUrl,
      startTime: exportEffect.startTime,
      endTime: exportEffect.endTime,
      removeSameType: false,
      effectId: exportEffect.id
    )
  }
  
  @IBAction func speedButtonDidTap(_ sender: UIButton) {
    // Change button state
    sender.isSelected = !sender.isSelected
    guard sender.isSelected else {
      // Undo speed effect
      let _ = CoreAPI.shared.coreAPI.undoLast(type: .time)
      return
    }
    
    let exportEffect = exportEffectProvider.provideSpeedExportEffect(type: .slowmo)
    guard let speedEffectType = exportEffect.additionalInfo[ExportEffectAdditionalInfoKey.name] as? SpeedEffectType else {
      return
    }
    EffectsAPI.shared.effectApplicator.applySpeedEffectType(
      speedEffectType,
      startTime: exportEffect.startTime,
      endTime: exportEffect.endTime,
      removeSameType: false,
      effectId: exportEffect.id
    )
  }
  
  @IBAction func musicButtonDidTap(_ sender: UIButton) {
    let hasSelectedTrack = sender.isSelected
    if hasSelectedTrack {
      showMusicControlsView()
    } else {
      applyMusicEffect()
      sender.isSelected = true
    }
  }
  
  @IBAction func effectButtonDidTap(_ sender: UIButton) {
    // Change button state
    sender.isSelected = !sender.isSelected
    guard sender.isSelected else {
      // Undo visual effect
      let _ = CoreAPI.shared.coreAPI.undoLast(type: .visual)
      return
    }
    let exportEffect = exportEffectProvider.provideVisualExportEffect(type: .vhs)
    guard let visualEffectType = exportEffect.additionalInfo[ExportEffectAdditionalInfoKey.name] as? VisualEffectApplicatorType else {
      return
    }
    EffectsAPI.shared.effectApplicator.applyVisualEffectApplicatorType(
      visualEffectType,
      startTime: exportEffect.startTime,
      endTime: exportEffect.endTime,
      removeSameType: false,
      effectId: exportEffect.id
    )
  }
  
  @IBAction func textButtonDidTap(_ sender: UIButton) {
    // Change button state
    sender.isSelected = !sender.isSelected
    guard sender.isSelected else {
      // Undo text effect
      let _ = CoreAPI.shared.coreAPI.undoLast(type: .text)
      return
    }
    
    applyOverlayEffect(type: .text)
  }
  
  @IBAction func gifButtonDidTap(_ sender: UIButton) {
    // Change button state
    sender.isSelected = !sender.isSelected
    guard sender.isSelected else {
      // Undo gif effect
      let _ = CoreAPI.shared.coreAPI.undoLast(type: .gif)
      return
    }
		
    applyOverlayEffect(type: .gif)
  }
  
  private func applyOverlayEffect(type: OverlayEffectApplicatorType) {
    let exportEffect = exportEffectProvider.provideOverlayExportEffect(type: type)
    guard let type = exportEffect.additionalInfo[ExportEffectAdditionalInfoKey.name] as? OverlayEffectApplicatorType,
          let effectInfo = exportEffect.additionalInfo[ExportEffectAdditionalInfoKey.effectInfo] as? VideoEditorEffectInfo else {
      return
    }
    
    EffectsAPI.shared.effectApplicator.applyOverlayEffectType(
      type,
      effectInfo: effectInfo
    )
  }
}

// MARK: - VideoEditorPlayerDelegate
extension EditorViewController: VideoEditorPlayerDelegate {
  func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime) {
    // Process player frames if needed
    print(time.seconds)
  }
  
  func playerDidEndPlaying(_ player: VideoEditorPlayable) {
    // proccess player did end playing if needed
    print("Did end playing")
  }
}

// MARK: - Music helpers
extension EditorViewController {
  func showMusicControlsView() {
    videoVolumeSlider.value = CoreAPI.shared.coreAPI.audioMixer?.volume(forTrackId: originalVideoAudioTrackId) ?? 1.0
    trackVolumeSlider.value = CoreAPI.shared.coreAPI.audioMixer?.volume(forTrackId: trackId) ?? 0.0
    
    UIView.animate(withDuration: 0.3, animations: {
      self.musicTrackControlsTopConstraint.constant = -300
      self.view.layoutIfNeeded()
    })
  }
  
  func hideMusicControlsView() {
    UIView.animate(
      withDuration: 0.3,
      animations: {
        self.musicTrackControlsTopConstraint.constant = self.view.safeAreaLayoutGuide.layoutFrame.height
        self.view.layoutIfNeeded()
      })
  }
  
  @IBAction func applyMusicSettingsTap(_ sender: Any) {
    // Apply music volume
    CoreAPI.shared.coreAPI.audioMixer?.setVolume(videoVolumeSlider.value, forTrackId: originalVideoAudioTrackId)
    CoreAPI.shared.coreAPI.audioMixer?.setVolume(trackVolumeSlider.value, forTrackId: trackId)
    
    applyVolumeChanges()
    
    hideMusicControlsView()
  }
  
  @IBAction func removeTrackTap(_ sender: Any) {
    guard let url = trackUrl else {
      return
    }
    CoreAPI.shared.coreAPI.videoAsset?.removeMusic(
      trackId: trackId,
      url: url
    )
    hideMusicControlsView()
    musicButton.isSelected = false
    
    reloadPlayer()
  }
  
  @IBAction func videoVolumeChanged(_ sender: Any) {
    CoreAPI.shared.coreAPI.audioMixer?.setVolume(videoVolumeSlider.value, forTrackId: originalVideoAudioTrackId)
    applyVolumeChanges()
  }
  
  @IBAction func trackVolumeChanged(_ sender: Any) {
    CoreAPI.shared.coreAPI.audioMixer?.setVolume(trackVolumeSlider.value, forTrackId: trackId)
    applyVolumeChanges()
  }
  
  private func applyVolumeChanges() {
    playableView?.videoEditorPlayer?.audioMix = CoreAPI.shared.coreAPI.audioMixer?.audioMix
  }
}

