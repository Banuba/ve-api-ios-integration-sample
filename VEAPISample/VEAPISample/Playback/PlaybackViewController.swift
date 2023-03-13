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
  
  // Video urls for playback
  var videoUrls: [URL]!

  // MARK: - Player container
  @IBOutlet weak var playerContainerView: UIView!
  
  @IBOutlet weak var volumeSlider: UISlider!
  @IBOutlet weak var playbackProgressSlider: UISlider!
  @IBOutlet weak var playPauseButton: UIButton!
  var isPlaying: Bool { playPauseButton.isSelected }
  
  // MARK: - VideoPlayableView
  private(set) var playableView: VideoPlayableView?
  
  // MARK: - Playback helpers
  private var player: VideoEditorPlayable? { playableView?.videoEditorPlayer }
  private var currentTime: CMTime { playableView?.videoEditorPlayer?.currentTimeInCMTime ?? .zero }
  private var videoDuration: CMTime { editor.videoAsset?.composition.duration ?? .zero }

  // MARK: - AppStateObserver
  // Pauses video when app collapsed and resumes when app unfolds. See AppStateObserverDelegate extension
  private var appStateObserver: AppStateObserver?
  
  // MARK: - Banuba Services used for playback
  // Video editor service stores resulted video asset and applied effects
  var editor: VideoEditorService!
  // Playback sdk provides playback view for previewing decorated video
  var playbackSDK: VEPlayback!
  
  // MARK: - Effect managing helpers
  private var effectsProvider: EffectsProvider!
  private var effectsManager: EffectsManager!
  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    effectsManager = EffectsManager(editor: editor)
    // Configure video editor service with video urls. Video must be downloaded
    setupVideoEditor(with: videoUrls)
    
    playbackSDK = VEPlayback(videoEditorService: editor)
    effectsProvider = EffectsProvider(totalVideoDuration: videoDuration)
    
    // Get playable view which will preview video editor asset
    let view = playbackSDK.getPlayableView(delegate: self)
    playableView = view
    playerContainerView.addSubview(view)
    
    // Listen app states to control playback
    appStateObserver = AppStateObserver(delegate: self)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    playableView?.frame = playerContainerView.bounds
  }
  
  /// Setup current video editor service for playback
  private func setupVideoEditor(with videoUrls: [URL]) {
    // Setup sequence name and location
    let sequenceName = UUID().uuidString
    let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(sequenceName)
    
    // Create sequence at location
    let videoSequence = VideoSequence(folderURL: folderURL)
    
    // Fill up sequence with videos
    videoUrls.forEach { videoURL in
      videoSequence.addVideo(
        at: videoURL,
        isSlideShow: false,
        transition: .normal
      )
    }
    
    // Create VideoEditorAsset from relevant sequence
    let videoEditorAsset = VideoEditorAsset(
      sequence: videoSequence,
      isGalleryAssets: true,
      isSlideShow: false,
      videoResolutionConfiguration: AppDelegate.videoResolutionConfiguration
    )

    // Set current video asset to video editor service
    editor.setCurrentAsset(videoEditorAsset)
    
    // Apply original track rotation for each asset track
    videoEditorAsset.tracksInfo.forEach { assetTrack in
      let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(assetTrack)
      effectsManager.applyTransformEffect(
        start: assetTrack.timeRangeInGlobal.start,
        end: assetTrack.timeRangeInGlobal.end,
        rotation: rotation
      )
    }
    
    // Set initial video size
    editor.videoSize = videoSequence.videos.map { video in
      let resolution = video.videoInfo.resolution
      let urlAsset = AVURLAsset(url: video.url)
      let preferredTransform = urlAsset.tracks(withMediaType: .video).first?.preferredTransform ?? .identity
      let rotatedResolution = resolution.applying(preferredTransform)
      return CGSize(
        width: abs(rotatedResolution.width),
        height: abs(rotatedResolution.height)
      )
    }.first!
  }

  // MARK: - Actions
  
  @IBAction func backAction(_ sender: Any) {
    player?.pausePlay()
    navigationController?.popViewController(animated: true)
  }
  
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
  
  @IBAction func addAREffectAction(_ sender: UISwitch) {
    if sender.isOn {
      let maskEffect = effectsProvider.provideMaskEffect(withName: "AsaiLines")
      effectsManager.applyMaskEffect(maskEffect)
    } else {
      effectsManager.undoMaskEffect()
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }
  
  @IBAction func addFXEffectAction(_ sender: UISwitch) {
    if sender.isOn {
      let vhs = effectsProvider.provideVisualEffect(type: .vhs)
      effectsManager.applyVisualEffect(vhs)
    } else {
      effectsManager.undoVisualEffect()
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }

  @IBAction func addRapidSpeedEffectAction(_ sender: UISwitch) {
    struct Storage {
      static var rapid: Effect?
    }
    if sender.isOn {
      Storage.rapid = effectsProvider.provideSpeedEffect(type: .rapid)
      effectsManager.applySpeedEffect(Storage.rapid!)
    } else {
      effectsManager.undoEffect(withId: Storage.rapid!.id)
      Storage.rapid = nil
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }
  
  @IBAction func addSlowMoSpeedEffectAction(_ sender: UISwitch) {
    struct Storage {
      static var slowmo: Effect?
    }
    if sender.isOn {
      Storage.slowmo = effectsProvider.provideSpeedEffect(type: .slowmo)
      effectsManager.applySpeedEffect(Storage.slowmo!)
    } else {
      editor.undo(withId: Storage.slowmo!.id)
      Storage.slowmo = nil
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }
  
  @IBAction func addTextEffectAction(_ sender: UISwitch) {
    if sender.isOn {
      let text = effectsProvider.provideOverlayEffect(type: .text)
      effectsManager.applyOverlayEffect(text)
    } else {
      editor.undoAll(type: .text)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }
  
  @IBAction func addStickerEffectAction(_ sender: UISwitch) {
    if sender.isOn {
      let sticker = effectsProvider.provideOverlayEffect(type: .gif)
      effectsManager.applyOverlayEffect(sticker)
    } else {
      editor.undoAll(type: .gif)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }
  
  @IBAction func addColorEffectAction(_ sender: UISwitch) {
    if sender.isOn {
      let color = effectsProvider.provideJapanColorEffect()
      effectsManager.applyColorEffect(color)
    } else {
      effectsManager.undoColorEffect()

    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }
  
  @IBAction func addMusicEffectAction(_ sender: UISwitch) {
    struct Storage {
      static var trackUrl: URL?
      static var trackId: CMPersistentTrackID?
    }
    
    if sender.isOn {
      let musicEffect = effectsProvider.provideMusicEffect()
      Storage.trackId = CMPersistentTrackID(musicEffect.id)
      Storage.trackUrl = musicEffect.additionalInfo[Effect.AdditionalInfoKey.url] as? URL
      effectsManager.applyMusicEffect(musicEffect)
    } else {
      effectsManager.undoMusicEffect(id: Storage.trackId!, url: Storage.trackUrl!)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
    // Get new instance of player to playback music track
    reloadPlayer()
  }
  
  @IBAction func addCustomEffectAction(_ sender: UISwitch) {
    if sender.isOn {
      let videoSize = player?.playerItem?.presentationSize ?? .zero
      // Place blur in center of video
      let customEffect = effectsProvider.provideOverlayEffect(
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
      effectsManager.applyOverlayEffect(customEffect)
    } else {
      editor.undoAll(type: .blur)
    }
    player?.reloadComposition(shouldAutoStart: isPlaying)
  }
  
  @IBAction func takeScreenshotAction(_ sender: Any) {
    guard let asset = editor.asset, let firstTrack = editor.videoAsset?.tracksInfo.first else { return }
    let previewExtractor = PreviewExtractor(
      asset: asset,
      thumbnailHeight: UIScreen.main.bounds.height
    )
    
    guard let cgImage = previewExtractor.extractPreview(at: currentTime)?.cgImage else {
      print("Extracting preview failed")
      return
    }
    
    let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(firstTrack)
    let imageRotation = UIImage.orientation(byRotation: rotation)
    let resultImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: imageRotation)
    
    let previewImageViewController = PreviewImageViewController()
    previewImageViewController.image = resultImage
    present(previewImageViewController, animated: true)
  }

  private func reloadPlayer() {
    // Get new instance of player to playback music track
    let player = playbackSDK.getPlayer(forExternalAsset: nil, delegate: self)
    
    // Setup new player
    playableView?.setPlayer(player, isThumbnailNeeded: false)
  }
}

// MARK: - VideoEditorPlayerDelegate
// Handling video editor player delegate methods
extension PlaybackViewController: VideoEditorPlayerDelegate {
  func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime) {
    let progress = time.seconds / videoDuration.seconds
    playbackProgressSlider.value = Float(progress)
  }
  
  func playerDidEndPlaying(_ player: VideoEditorPlayable) {
    print("Did end playing")
  }
}

// MARK: - App state observer
// Helps to control playback when app resigns active and backs to active states
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
