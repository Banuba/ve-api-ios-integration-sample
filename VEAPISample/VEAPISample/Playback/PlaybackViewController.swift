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

class PlaybackViewController: UIViewController {
    
    private let oneSecond = CMTime(seconds: 1.0, preferredTimescale: 1_000)
    
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
    
    // MARK: - AppStateObserver
    // Pauses video when app collapsed and resumes when app unfolds. See AppStateObserverDelegate extension
    private var appStateObserver: AppStateObserver?
    
    private let videoEditorModule = AppDelegate.videoEditorModule
    private var playbackManager: PlaybackManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playbackManager = PlaybackManager(
            videoEditorModule: videoEditorModule,
            videoUrls: videoUrls
        )
        
        // Get playable view which will preview video editor asset
        let view = playbackManager.providePlaybackView(delegate: self)
        playableView = view
        playerContainerView.addSubview(view)
        
        // Listen app states to control playback
        appStateObserver = AppStateObserver(delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Layout playable view
        playableView?.frame = playerContainerView.bounds
    }
    
    // MARK: - Actions
    
    @IBAction func backAction(_ sender: Any) {
        playbackManager.player?.pausePlay()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playPauseAction(_ sender: UIButton) {
        let isPlaying = sender.isSelected
        if isPlaying {
            playbackManager.player?.pausePlay()
        } else {
            playbackManager.player?.startPlay(loop: true, fixedSpeed: false)
        }
        sender.isSelected.toggle()
    }
    
    @IBAction func playbackProgressChangedAction(_ slider: UISlider) {
        if slider.isTracking {
            playbackManager.player?.pausePlay()
            playbackManager.player?.playerDelegate = nil
        } else {
            if isPlaying {
                playbackManager.player?.startPlay(loop: true, fixedSpeed: false)
            }
            playbackManager.player?.playerDelegate = self
        }
        
        let time = CMTime(
            seconds: Double(slider.value) * playbackManager.videoDuration.seconds,
            preferredTimescale: playbackManager.videoDuration.timescale
        )
        seek(to: time)
    }
    
    @IBAction func volumeChangedAction(_ slider: UISlider) {
        playbackManager.setVideoVolume(slider.value)
    }
    
    @IBAction func seekForwardAction(_ sender: Any) {
        let time = playbackManager.currentTime + oneSecond
        seek(to: time)
    }
    
    @IBAction func seekBackwardAction(_ sender: Any) {
        let time = playbackManager.currentTime - oneSecond
        seek(to: time)
    }
    
    @IBAction func rewindAction(_ sender: Any) {
        seek(to: .zero)
    }
    
    private func seek(to time: CMTime) {
        let playbackRange = CMTimeRange(start: .zero, duration: playbackManager.videoDuration)
        
        var seekTime: CMTime = .zero
        
        if playbackRange.containsTime(time) {
            seekTime = time
        }
        
        playbackManager.player?.seek(to: seekTime)
    }
    
    @IBAction func addAREffectAction(_ sender: UISwitch) {
        if sender.isOn {
            let maskEffect = playbackManager.effectsProvider.provideMaskEffect(withName: "AsaiLines")
            playbackManager.effectsManager.applyMaskEffect(maskEffect)
        } else {
            playbackManager.effectsManager.undoMaskEffect()
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func addFXEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            let vhs = playbackManager.effectsProvider.provideVisualEffect(type: .vhs)
            playbackManager.effectsManager.applyVisualEffect(vhs)
        } else {
            playbackManager.effectsManager.undoVisualEffect()
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func addRapidSpeedEffectAction(_ sender: UISwitch) {
        struct Storage {
            static var rapid: Effect?
        }
        if sender.isOn {
            Storage.rapid = playbackManager.effectsProvider.provideSpeedEffect(type: .rapid)
            playbackManager.effectsManager.applySpeedEffect(Storage.rapid!)
        } else {
            playbackManager.effectsManager.undoEffect(withId: Storage.rapid!.id)
            Storage.rapid = nil
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func addSlowMoSpeedEffectAction(_ sender: UISwitch) {
        struct Storage {
            static var slowmo: Effect?
        }
        if sender.isOn {
            Storage.slowmo = playbackManager.effectsProvider.provideSpeedEffect(type: .slowmo)
            playbackManager.effectsManager.applySpeedEffect(Storage.slowmo!)
        } else {
            playbackManager.effectsManager.undoEffect(withId: Storage.slowmo!.id)
            Storage.slowmo = nil
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func addTextEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            let text = playbackManager.effectsProvider.provideOverlayEffect(type: .text)
            playbackManager.effectsManager.applyOverlayEffect(text)
        } else {
            playbackManager.effectsManager.undoAll(type: .text)
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func addStickerEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            let sticker = playbackManager.effectsProvider.provideOverlayEffect(type: .gif)
            playbackManager.effectsManager.applyOverlayEffect(sticker)
        } else {
            playbackManager.effectsManager.undoAll(type: .gif)
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func addColorEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            let color = playbackManager.effectsProvider.provideJapanColorEffect()
            playbackManager.effectsManager.applyColorEffect(color)
        } else {
            playbackManager.effectsManager.undoColorEffect()
            
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func addMusicEffectAction(_ sender: UISwitch) {
        struct Storage {
            static var trackUrl: URL?
            static var trackId: CMPersistentTrackID?
        }
        
        if sender.isOn {
            let musicEffect = playbackManager.effectsProvider.provideMusicEffect()
            Storage.trackId = CMPersistentTrackID(musicEffect.id)
            Storage.trackUrl = musicEffect.additionalInfo[Effect.AdditionalInfoKey.url] as? URL
            playbackManager.effectsManager.applyMusicEffect(musicEffect)
        } else {
            playbackManager.effectsManager.undoMusicEffect(id: Storage.trackId!, url: Storage.trackUrl!)
        }
        // Get new instance of player to playback music track
        playbackManager.reloadPlayer(delegate: self)
    }
    
    @IBAction func addCustomEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            let videoSize = playbackManager.player?.playerItem?.presentationSize ?? .zero
            // Place blur in center of video
            let customEffect = playbackManager.effectsProvider.provideOverlayEffect(
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
            playbackManager.effectsManager.applyOverlayEffect(customEffect)
        } else {
            playbackManager.effectsManager.undoAll(type: .blur)
        }
        playbackManager.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    @IBAction func takeScreenshotAction(_ sender: Any) {
        guard let screenshot = playbackManager.takeScreenshot() else {
            return
        }
        
        let previewImageViewController = PreviewImageViewController()
        previewImageViewController.image = screenshot
        present(previewImageViewController, animated: true)
    }
}

// MARK: - VideoEditorPlayerDelegate
// Handling video editor player delegate methods
extension PlaybackViewController: VideoEditorPlayerDelegate {
    func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime) {
        let progress = time.seconds / playbackManager.videoDuration.seconds
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
        playbackManager.player?.stopPlay()
    }
    
    func applicationDidBecomeActive(_ appStateObserver: AppStateObserver) {
        if isPlaying {
            playbackManager.player?.startPlay(loop: true, fixedSpeed: false)
        }
    }
}
