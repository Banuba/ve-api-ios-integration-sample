//
//  PlaybackViewController.swift
//  VEAPISample
//
//  Created by Banuba on 28.12.22.
//

import UIKit
import AVFoundation

// Banuba Modules
import VideoEditor
import VEPlaybackSDK
import VEEffectsSDK
import BanubaUtilities

private struct Defaults {
  static let oneSecond = CMTime(seconds: 1.0, preferredTimescale: 1_000)
}

class PlaybackViewController: UIViewController {
  
  // Must be initialized before presenting
  var videoUrls: [URL]!

  // MARK: - Player container
  @IBOutlet weak var playerContainerView: UIView!
  
  @IBOutlet weak var volumeSlider: UISlider!
  @IBOutlet weak var playbackProgressSlider: UISlider!
  @IBOutlet weak var playPauseButton: UIButton!
  var isPlaying: Bool { playPauseButton.isSelected }
  
  // MARK: - VideoPlayableView
  var playableView: VideoPlayableView?
  var player: VideoEditorPlayable? { playableView?.videoEditorPlayer }
  var currentTime: CMTime { playableView?.videoEditorPlayer?.currentTimeInCMTime ?? .zero }
  var videoDuration: CMTime { editor.videoAsset?.composition.duration ?? .zero }

  // MARK: - AppStateObserver
  var appStateObserver: AppStateObserver?
  
  // MARK: - Banuba Services
  // Initilize before use. See method seetupPlaybackServices()
  var editor: VideoEditorService!
  var effectApplicator: EffectApplicator!
  var playbackSDK: VEPlayback!
  
  private var effectsProvider: ExportEffectProvider!
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    seetupPlaybackServices()
    setupPlayback(with: videoUrls)
    setupPlaybackView()
    setupAppStateHandler()
    
    effectsProvider = ExportEffectProvider(totalVideoDuration: videoDuration)
  }
}

// MARK: - Actions
extension PlaybackViewController {
  @IBAction func playPauseAction(_ sender: UIButton) {
    let isPlaying = sender.isSelected
    if isPlaying {
      player?.pausePlay()
    } else {
      player?.startPlay(loop: true, fixedSpeed: false)
    }
    sender.isSelected.toggle()
  }
  
  @IBAction func playbackProgressChangedAction(_ slider: UISlider) {
    if slider.isTracking {
      player?.pausePlay()
      player?.playerDelegate = nil
    } else {
      if isPlaying {
        player?.startPlay(loop: true, fixedSpeed: false)
      }
      player?.playerDelegate = self
    }
    
    let time = CMTime(
      seconds: Double(slider.value) * videoDuration.seconds,
      preferredTimescale: videoDuration.timescale
    )
    seek(to: time)
  }
  
  @IBAction func volumeChangedAction(_ slider: UISlider) {
    editor.setAudioTrackVolume(slider.value, to: player)
  }
  
  @IBAction func seekForwardAction(_ sender: Any) {
    let time = currentTime + Defaults.oneSecond
    seek(to: time)
  }
  
  @IBAction func seekBackwardAction(_ sender: Any) {
    let time = currentTime - Defaults.oneSecond
    seek(to: time)
  }
  
  @IBAction func rewindAction(_ sender: Any) {
    seek(to: .zero)
  }
  
  private func seek(to time: CMTime) {
    let playbackRange = CMTimeRange(start: .zero, duration: videoDuration)
    
    var seekTime: CMTime = .zero
    
    if playbackRange.containsTime(time) {
      seekTime = time
    }
    
    player?.seek(to: seekTime)
  }
  
  @IBAction func addAREffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .mask)
    } else {
      let effect = effectsProvider.provideMaskEffect(withName: "AsaiLines")
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func addFXEffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .visual)
    } else {
      let effect = effectsProvider.provideVisualExportEffect(type: .vhs)
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func addRapidSpeedEffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .time)
    } else {
      let effect = effectsProvider.provideSpeedExportEffect(type: .rapid)
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func addSlowMoSpeedEffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .time)
    } else {
      let effect = effectsProvider.provideSpeedExportEffect(type: .slowmo)
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func addTextEffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .text)
    } else {
      let effect = effectsProvider.provideOverlayExportEffect(type: .text)
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func addColorEffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .color)
    } else {
      let effect = effectsProvider.provideColorExportEffect()
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func addStickerEffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .gif)
    } else {
      let effect = effectsProvider.provideOverlayExportEffect(type: .gif)
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func addMusicEffectAction(_ sender: EffectButton) {
    struct AppliedTrackInfo {
      static var url: URL?
      static var id: CMPersistentTrackID?
    }
    
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.videoAsset?.removeMusic(trackId: AppliedTrackInfo.id!, url: AppliedTrackInfo.url!)
    } else {
      let effect = effectsProvider.provideMusicExportEffect()
      AppliedTrackInfo.id = CMPersistentTrackID(effect.id)
      AppliedTrackInfo.url = effect.additionalInfo[ExportEffectAdditionalInfoKey.url] as? URL
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
    // Get new instance of player to playback music track
    reloadPlayer()
  }
  
  @IBAction func addCustomEffectAction(_ sender: EffectButton) {
    let isEffectApplied = sender.isSelected
    if isEffectApplied {
      editor.undoAll(type: .blur)
    } else {
      let videoSize = player?.playerItem?.presentationSize ?? .zero
      // Place blur in center of video
      let effect = effectsProvider.provideOverlayExportEffect(
        type: .blur(
          drawableFigure: .circle,
          coordinates: BlurCoordinateParams(
            center: CGPoint(x: videoSize.width / 2.0, y: videoSize.height / 2.0),
            width: videoSize.width,
            height: videoSize.height,
            radius: videoSize.width * 0.2
          )
        )
      )
      applyEffect(effect)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    sender.isSelected.toggle()
  }
  
  @IBAction func takeScreenshotAction(_ sender: Any) {
    guard let asset = editor.asset else { return }
    let previewExtractor = PreviewExtractor(
      asset: asset,
      thumbnailHeight: UIScreen.main.bounds.height
    )
    guard let image = previewExtractor.extractPreview(at: currentTime) else {
      print("Extracting preview failed")
      return
    }
    let previewImageViewController = PreviewImageViewController()
    previewImageViewController.image = image
    present(previewImageViewController, animated: true)
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
    let view = playbackSDK.getPlayableView(delegate: self)
    playableView = view
    // Setup view frame
    view.frame = playerContainerView.bounds
    playerContainerView.addSubview(view)
    
    self.view.layoutIfNeeded()
  }
  
  private func reloadPlayer() {
    // Get new instance of player to playback music track
    let player = playbackSDK.getPlayer(forExternalAsset: nil, delegate: self)
    
    // Setup new player
    playableView?.setPlayer(player, isThumbnailNeeded: false)
  }
  
  func setupAppStateHandler() {
    appStateObserver = AppStateObserver(delegate: self)
  }
}

// MARK: - App state observer
extension PlaybackViewController: AppStateObserverDelegate {
  func applicationWillResignActive(_ appStateObserver: AppStateObserver) {
    player?.stopPlay()
  }
  func applicationDidBecomeActive(_ appStateObserver: AppStateObserver) {
    if isPlaying {
      player?.startPlay(loop: true, fixedSpeed: false)
    }
  }
}

// MARK: - Action
extension PlaybackViewController {
  
  @IBAction func backAction(_ sender: Any) {
    player?.pausePlay()
    navigationController?.popViewController(animated: true)
  }
}

// MARK: - VideoEditorPlayerDelegate
extension PlaybackViewController: VideoEditorPlayerDelegate {
  func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime) {
    let progress = time.seconds / videoDuration.seconds
    playbackProgressSlider.value = Float(progress)
  }
  
  func playerDidEndPlaying(_ player: VideoEditorPlayable) {
    print("Did end playing")
  }
}
