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

class PlaybackViewController: UIViewController, AppStateObserverDelegate {
    
    private let oneSecond = CMTime(seconds: 1.0, preferredTimescale: 1_000)
    
    // Video urls for playback
    var selectedVideoContent: [URL]!
    
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playbackProgressSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    
    // MARK: - AppStateObserver
    // Pauses video when app collapsed and resumes when app unfolds. See AppStateObserverDelegate extension
    private var appStateObserver: AppStateObserver?
    
    private var playbackManager: PlaybackManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playbackManager = PlaybackManager(videoEditorModule: AppDelegate.videoEditorModule)
        playbackManager.addVideoContent(with: selectedVideoContent)
        playbackManager.setSurfaceView(playerContainerView: playerContainerView)
        
        playbackManager.progressCallback = { [weak self] progress in
            self?.playbackProgressSlider.value = progress
        }
        
        // Listen app states to control playback
        appStateObserver = AppStateObserver(delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // layout player surface here for demo purposes using frame-based layout
        let playableView = playerContainerView.subviews.first
        playableView?.frame = playerContainerView.bounds
    }
    
    func applicationWillResignActive(_ appStateObserver: AppStateObserver) {
        playbackManager.pause()
    }
    
    func applicationDidBecomeActive(_ appStateObserver: AppStateObserver) {
        let isPlayingBeforeResigningActive = playPauseButton.isSelected
        if isPlayingBeforeResigningActive {
            playbackManager.play(loop: true)
        }
    }
    
    // MARK: - Actions
    @IBAction func backAction(_ sender: Any) {
        playbackManager.pause()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playPauseAction(_ sender: UIButton) {
        let isPlaying = sender.isSelected
        if isPlaying {
            playbackManager.pause()
        } else {
            playbackManager.play(loop: true)
        }
        sender.isSelected.toggle()
    }
    
    @IBAction func playbackProgressChangedAction(_ slider: UISlider) {
        if slider.isTracking {
            playbackManager.pause()
            playbackManager.stopTrackingPlayerProgress()
        } else {
            let isPlaying = playPauseButton.isSelected
            if isPlaying {
                playbackManager.play(loop: true)
            }
            playbackManager.startTrackingPlayerProgress()
        }
        
        let time = CMTime(
            seconds: Double(slider.value) * playbackManager.videoDuration.seconds,
            preferredTimescale: playbackManager.videoDuration.timescale
        )
        playbackManager.seek(to: time)
    }
    
    @IBAction func volumeChangedAction(_ slider: UISlider) {
        playbackManager.setVideoVolume(slider.value)
    }
    
    @IBAction func seekForwardAction(_ sender: Any) {
        let time = playbackManager.currentPostionTime + oneSecond
        playbackManager.seek(to: time)
    }
    
    @IBAction func seekBackwardAction(_ sender: Any) {
        let time = playbackManager.currentPostionTime - oneSecond
        playbackManager.seek(to: time)
    }
    
    @IBAction func rewindAction(_ sender: Any) {
        playbackManager.seek(to: .zero)
    }
    
    @IBAction func addAREffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyMaskEffect()
        } else {
            playbackManager.undoMaskEffect()
        }
    }
    
    @IBAction func addFXEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyFXEffect()
        } else {
            playbackManager.undoFXEffect()
        }
    }
    
    @IBAction func addRapidSpeedEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyRapidSpeedEffect()
        } else {
            playbackManager.undoRapidSpeedEffect()
        }
    }
    
    @IBAction func addSlowMoSpeedEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applySlowoSpeedEffect()
        } else {
            playbackManager.undoSlowmoSpeedEffect()
        }
    }
    
    @IBAction func addTextEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyTextEffect()
        } else {
            playbackManager.undoTextEffect()
        }
    }
    
    @IBAction func addStickerEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyStickerEffect()
        } else {
            playbackManager.undoStickerEffect()
        }
    }
    
    @IBAction func addColorEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyColorEffect()
        } else {
            playbackManager.undoColorEffect()
        }
    }
    
    @IBAction func addMusicEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyMusicEffect()
        } else {
            playbackManager.undoMusicEffect()
        }
    }
    
    @IBAction func addCustomEffectAction(_ sender: UISwitch) {
        if sender.isOn {
            playbackManager.applyCustomEffect()
        } else {
            playbackManager.undoCustomEffect()
        }
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
