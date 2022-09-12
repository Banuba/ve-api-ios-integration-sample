//
//  EditorViewController.swift
//  VEAPISample
//
//  Created by Gleb Markin on 10.03.22.
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
    
    // MARK: - Music track id
    var trackId: CMPersistentTrackID = .zero
    var trackUrl: URL?
    
    // MARK: - Unique effect id
    var uniqueEffectId: UInt {
        UInt.random(in: 0...100)
    }
    
    // MARK: - VideoPlayableView
    var playableView: VideoPlayableView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup playback view with container frame size
        setupPlaybackView()
        // Setup navigation buttons
        setupNavigationButtons()
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
            watermarkFilterModel: watermarkModel
        ) { [weak self] isSuccess, error in
            // Return to main thread
            DispatchQueue.main.async {
                // Stop activity indicator
                self?.activityIndicator.stopAnimating()
            }
            if let error = error {
                // Proccess error
                print(error.localizedDescription)
            } else {
                self?.saveVideoToGallery(fileURL: fileURL.relativePath)
            }
        }
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
    func applyColorEffect() {
        // Color URL
        guard let url = Bundle.main.url(forResource: "luts/japan", withExtension: "png") else {
            return
        }
        // Apply color filter with following url and parmas
        EffectsAPI.shared.effectApplicator.applyColorEffect(
            name: "Japan",
            lutUrl: url,
            startTime: .zero,
            endTime: .indefinite,
            removeSameType: false,
            effectId: EffectIDs.colorEffectStartId + uniqueEffectId
        )
    }
    
    func applySpeedEffect() {
        // Apply speed effect
        EffectsAPI.shared.effectApplicator.applySpeedEffectType(
            .rapid,
            startTime: .zero,
            endTime: .indefinite,
            removeSameType: false,
            effectId: EffectIDs.speedEffectStartId + uniqueEffectId
        )
    }
    
    func applyVisualEffect() {
        // Apply visual effect
        EffectsAPI.shared.effectApplicator.applyVisualEffectApplicatorType(
            .vhs,
            startTime: .zero,
            endTime: .indefinite,
            removeSameType: false,
            effectId: EffectIDs.visualEffectStartId + uniqueEffectId
        )
    }
    
    // Apply text  or gif effect
    func applyOverlayEffect(withType type: OverlayEffectApplicatorType) {
        // Ouput image should be created from cgImage reference
        var image: UIImage?
        
        switch type {
        case .gif:
            image = createGifImage()
        case .text:
            image = createTextImage()
        default: break
        }
        
        
        guard let outputImage = image else {
            return
        }
        // Create required effect settings
        let info = createEffectInfo(withImage: outputImage, for: type)
        
        // Apply effect
        EffectsAPI.shared.effectApplicator.applyOverlayEffectType(type, effectInfo: info)
    }
    
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
        let id = CMPersistentTrackID(uniqueEffectId)
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
        // Apply color effect
        applyColorEffect()
    }
  @IBAction func musicButtonDidTap(_ sender: UIButton) {
    // Change button state
    sender.isSelected = !sender.isSelected
    guard sender.isSelected else {
      // Undo music effect
      guard let url = trackUrl else {
        return
      }
      CoreAPI.shared.coreAPI.videoAsset?.removeMusic(
        trackId: trackId,
        url: url
      )
      // Get new instance of player to playback music track
      reloadPlayer()
      return
    
    @IBAction func speedButtonDidTap(_ sender: UIButton) {
        // Change button state
        sender.isSelected = !sender.isSelected
        guard sender.isSelected else {
            // Undo speed effect
            let _ = CoreAPI.shared.coreAPI.undoLast(type: .time)
            return
        }
        // Apply color effect
        applySpeedEffect()
    }
    
    }
    // Apply color effect
    applyMusicEffect()
  }
    
    @IBAction func effectButtonDidTap(_ sender: UIButton) {
        // Change button state
        sender.isSelected = !sender.isSelected
        guard sender.isSelected else {
            // Undo visual effect
            let _ = CoreAPI.shared.coreAPI.undoLast(type: .visual)
            return
        }
        // Apply color effect
        applyVisualEffect()
    }
    
    @IBAction func textButtonDidTap(_ sender: UIButton) {
        // Change button state
        sender.isSelected = !sender.isSelected
        guard sender.isSelected else {
            // Undo text effect
            let _ = CoreAPI.shared.coreAPI.undoLast(type: .text)
            return
        }
        // Apply color effect
        applyOverlayEffect(withType: .text)
    }
    
    @IBAction func gifButtonDidTap(_ sender: UIButton) {
        // Change button state
        sender.isSelected = !sender.isSelected
        guard sender.isSelected else {
            // Undo gif effect
            let _ = CoreAPI.shared.coreAPI.undoLast(type: .gif)
            return
        }
        // Apply color effect
        applyOverlayEffect(withType: .gif)
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

// MARK: - Gif and Text helpers
extension EditorViewController {
    // Create text image
    func createTextImage() -> UIImage?{
        // Background creation
        let height = 40
        let width = 120
        
        let numComponents = 3
        let numBytes = height * width * numComponents
        
        let pixelData = [UInt8](repeating: 210, count: numBytes)
        let colorspace = CGColorSpaceCreateDeviceRGB()
        
        let rgbData = CFDataCreate(nil, pixelData, numBytes)!
        let provider = CGDataProvider(data: rgbData)!
        
        let rgbImageRef = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8 * numComponents,
            bytesPerRow: width * numComponents,
            space: colorspace,
            bitmapInfo: CGBitmapInfo(rawValue: 0),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent
        )!
        
        let image = UIImage(cgImage: rgbImageRef)
        
        // Text creation
        UIGraphicsBeginImageContext(image.size)
        
        let text = "Hello world!"
        let rect = CGRect(origin: .zero, size: image.size)
        image.draw(in: rect)
        
        let font = UIFont(name: "Helvetica-Bold", size: 14)!
        let textColor = UIColor.white
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        
        let attributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: textStyle,
            NSAttributedString.Key.foregroundColor: textColor
        ]
        
        let textHeight = font.lineHeight
        let textY = (image.size.height - textHeight) / 2
        let textRect = CGRect(
            x: .zero,
            y: textY,
            width: image.size.width,
            height: textHeight
        )
        
        text.draw(in: textRect.integral, withAttributes: attributes)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result
    }
    
    // MARK: - Gif image
    // Create gif from sample resource
    func createGifImage() -> UIImage? {
        guard let path = Bundle.main.path(forResource: "GifExample", ofType: "gif") else {
            print("Gif does not exist at that path")
            return nil
        }
        
        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
              let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }
        
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        
        let gifImage = UIImage.animatedImage(with: images, duration: 0.4)
        
        return gifImage
    }
    
    // Create VideoEditorEffectInfo instance
    func createEffectInfo(
        withImage image: UIImage,
        for type: OverlayEffectApplicatorType
    ) -> VideoEditorEffectInfo {
        
        // Relevant screen points
        var points: ImagePoints?
        
        switch type {
        case .gif:
            points = gifImagePoints
        case .text:
            points = textImagePoints
        default: break
        }
        
        // Result effect info
        let effectInfo = VideoEditorEffectInfo(
            id: UInt.random(in: 0...1000),
            image: image,
            relativeScreenPoints: points,
            start: .zero,
            end: .indefinite
        )
        
        return effectInfo
    }
    
    // MARK: - ImagePoints helpers
    // Gif image points
    var gifImagePoints: ImagePoints {
        ImagePoints(
            leftTop: CGPoint(x: 0.15, y: 0.45),
            rightTop: CGPoint(x: 0.8, y: 0.45),
            leftBottom: CGPoint(x: 0.15, y: 0.55),
            rightBottom: CGPoint(x: 0.8, y: 0.55)
        )
    }
    
    // Text image points
    var textImagePoints: ImagePoints {
        ImagePoints(
            leftTop: CGPoint(x: 0.15, y: 0.25),
            rightTop: CGPoint(x: 0.8, y: 0.25),
            leftBottom: CGPoint(x: 0.15, y: 0.35),
            rightBottom: CGPoint(x: 0.8, y: 0.35)
        )
    }
}

    
    
    
    }
    
    
}

