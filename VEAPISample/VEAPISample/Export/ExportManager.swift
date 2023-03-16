//
//  ExportManager.swift
//  VEAPISample
//
//  Created by Andrei Sak on 16.03.23.
//

import AVFoundation

import BanubaUtilities
import VideoEditor
import VEExportSDK
import VEEffectsSDK

class ExportManager {
    // MARK: - Banuba Services used for export
    // Video editor service stores video asset and applied effects
    let editor: VideoEditorService
    // Export sdk provides export video methods
    let exportSDK: VEExport
    // Setups render size
    let videoResolutionConfiguration: VideoResolutionConfiguration
    // Applies and cancels effects
    private let effectsManager: EffectsManager
    
    private var videoSequence: VideoSequence?
    
    init(videoEditorModule: VideoEditorModule) {
        self.editor = videoEditorModule.editor
        self.videoResolutionConfiguration = videoEditorModule.videoResolutionConfiguration
        
        self.exportSDK = VEExport(videoEditorService: editor)!
        self.effectsManager = EffectsManager(editor: editor)
    }
    
    deinit {
        guard let videoSequence else { return }
        // Clean up video sequence resources
        try? FileManager.default.removeItem(at: videoSequence.folderURL)
    }
    
    func setupVideoContent(with videoUrls: [URL]) {
        // Create videoSequence of video by provided video urls
        // VideoSequence entity helps to manage video in sequence and stores additional info
        let videoSequence = createVideoSequence(with: videoUrls)
        self.videoSequence = videoSequence
        
        // Create VideoEditorAsset from relevant sequence
        // VideoEditorAsset is entity of VideoEditor used for export
        let videoEditorAsset = VideoEditorAsset(
            sequence: videoSequence,
            isGalleryAssets: true,
            isSlideShow: false,
            videoResolutionConfiguration: videoResolutionConfiguration
        )
        
        // Set current video asset to video editor service
        editor.setCurrentAsset(videoEditorAsset)
        
        // Apply original video rotation as effect
        adjustVideoEditorAssetTracksRotation(videoEditorAsset)
        
        // Setup preview render size
        setupRenderSize(videoSequence: videoSequence)
    }
    
    /// Export video to provided url with progress callback and completion
    func exportVideo(
        progressCallback: ((_ progress: Float) -> Void)?,
        completion: ((_ fileURL: URL?, _ success: Bool, _ error: Error?) -> Void)?
    ) -> CancelExportHandler? {
        // Prepare video effects
        prepareEffects()
        
        // Prepare result video url
        let resultVideoUrl = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.mov")
        if FileManager.default.fileExists(atPath: resultVideoUrl.path) {
            try? FileManager.default.removeItem(at: resultVideoUrl)
        }
        
        // Export settings
        let exportVideoInfo = ExportVideoInfo(
            resolution: .fullHd1080,
            useHEVCCodecIfPossible: true
        )
        
        // Prepare watermark
        let watermark = prepareWatermark(image: UIImage(named: "banuba_watermark")!)
        
        return exportSDK.exportVideo(
            to: resultVideoUrl,
            using: exportVideoInfo,
            watermarkFilterModel: watermark,
            exportProgress: { progress in progressCallback?(Float(progress)) },
            completion: { success, error in completion?(resultVideoUrl, success, error) }
        )
    }
    
    /// Returns screenshot at specific time
    func takeScreenshot(of asset: AVURLAsset, at seconds: TimeInterval) -> UIImage? {
        let previewExtractor = PreviewExtractor(
            asset: asset,
            thumbnailHeight: UIScreen.main.bounds.height
        )
        
        let screenshotTime = CMTime(seconds: seconds, preferredTimescale: 1_000)
        guard let image = previewExtractor.extractPreview(at: screenshotTime) else {
            print("Extracting screenshot failed")
            return nil
        }
        
        return image
    }
    
    // Create video sequence with specific name and location
    private func createVideoSequence(with videoUrls: [URL]) -> VideoSequence {
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
        
        return videoSequence
    }
    
    // Apply original track rotation for each asset track
    private func adjustVideoEditorAssetTracksRotation(_ videoEditorAsset: VideoEditorAsset) {
        videoEditorAsset.tracksInfo.forEach { assetTrack in
            let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(assetTrack)
            effectsManager.applyTransformEffect(
                start: assetTrack.timeRangeInGlobal.start,
                end: assetTrack.timeRangeInGlobal.end,
                rotation: rotation
            )
        }
    }
    
    // Configure render video size according to video aspect and videoResolutionConfiguration
    private func setupRenderSize(videoSequence: VideoSequence) {
        let videoSize = videoSequence.videos.map { video in
            let resolution = video.videoInfo.resolution
            let urlAsset = AVURLAsset(url: video.url)
            let preferredTransform = urlAsset.tracks(withMediaType: .video).first?.preferredTransform ?? .identity
            let rotatedResolution = resolution.applying(preferredTransform)
            return CGSize(
                width: abs(rotatedResolution.width),
                height: abs(rotatedResolution.height)
            )
        }.first!
        
        let videoAspect = VideoAspectRatioCalculator.calculateVideoAspectRatio(withVideoSize: videoSize)
        
        editor.videoSize = VideoAspectRatioCalculator.adjustVideoSize(
            videoResolutionConfiguration.current.size,
            withAspectRatio: videoAspect
        )
    }
    
    private func prepareEffects() {
        guard let videoEditorAsset = editor.videoAsset else {
            debugPrint("VideoEditorAsset is not configured!")
            return
        }
        let effectsProvider = EffectsProvider()
        effectsProvider.totalVideoDuration = videoEditorAsset.composition.duration
        
        let colorEffect = effectsProvider.provideJapanColorEffect()
        effectsManager.applyColorEffect(colorEffect)
        
        let visualEffect = effectsProvider.provideVisualEffect(type: .vhs)
        effectsManager.applyVisualEffect(visualEffect)
        
        let slowmo = effectsProvider.provideSpeedEffect(type: .slowmo)
        effectsManager.applySpeedEffect(slowmo)
        
        let sticker = effectsProvider.provideOverlayEffect(type: .gif)
        effectsManager.applyOverlayEffect(sticker)
        
        let text = effectsProvider.provideOverlayEffect(type: .text)
        effectsManager.applyOverlayEffect(text)
        
        let music = effectsProvider.provideMusicEffect()
        effectsManager.applyMusicEffect(music)
        
        let maskEffect = effectsProvider.provideMaskEffect()
        effectsManager.applyMaskEffect(maskEffect)
    }
    
    // Returns watermark for specific image
    func prepareWatermark(image: UIImage) -> VideoEditorFilterModel {
        let watermarkApplicator = WatermarkApplicator()
        
        // Make watermark size equals videoSize / 3
        let watermarkAspect = image.size.height / image.size.width
        let watermarkWidth = videoResolutionConfiguration.current.size.width / 3.0
        let watermarkSize = CGSize(
            width: watermarkWidth,
            height: watermarkWidth * watermarkAspect
        )
        
        return watermarkApplicator.adjustWatermarkEffect(
            configuration: WatermarkConfiguration(
                watermark: ImageConfiguration(image: image),
                size: watermarkSize,
                sharedOffset: 30.0,
                position: .rightBottom
            ),
            videoSize: videoResolutionConfiguration.current.size
        )
    }
}
