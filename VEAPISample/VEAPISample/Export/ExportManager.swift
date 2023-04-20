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
    let videoEditorService: VideoEditorService
    // Export sdk provides export video methods
    let exportSDK: VEExport
    // Setups render size
    let videoResolutionConfiguration: VideoResolutionConfiguration
    
    private var videoSequence: VideoSequence?
    
    private let effectApplicator: EffectApplicator
    
    private var totalVideoDuration: CMTime = .zero
    
    init(videoEditorModule: VideoEditorApiModule) {
        self.videoEditorService = videoEditorModule.editor
        self.videoResolutionConfiguration = videoEditorModule.videoResolutionConfiguration
        
        self.exportSDK = VEExport(videoEditorService: videoEditorService)!
        
        self.effectApplicator = EffectApplicator(
            editor: videoEditorService,
            effectConfigHolder: EditorEffectsConfigHolder(token: AppDelegate.licenseToken)
        )
    }
    
    deinit {
        // Clear video editor service asset
        videoEditorService.setCurrentAsset(nil)
        
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
        videoEditorService.setCurrentAsset(videoEditorAsset)
        
        // Apply original video rotation as effect
        adjustVideoEditorAssetTracksRotation(videoEditorAsset)
        
        // Setup preview render size
        setupRenderSize(videoSequence: videoSequence)
    }
    
    /// Export video to provided url with progress callback and completion
    func exportVideo(
        progressCallback: ((_ progress: Float) -> Void)?,
        completion: ((_ fileURL: URL?, _ error: Error?) -> Void)?
    ) -> CancelExportHandler? {
        // Prepare video effects
        prepareEffects()
        
        let filename = "tmp.mov"
        // Prepare result video url
        let resultVideoUrl = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
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
            completion: { error in completion?(resultVideoUrl, error) }
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
            effectApplicator.addTransformEffect(
                atStartTime: assetTrack.timeRangeInGlobal.start,
                end: assetTrack.timeRangeInGlobal.end,
                rotation: rotation,
                isVideoFitsAspect: false
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
        
        videoEditorService.videoSize = VideoAspectRatioCalculator.adjustVideoSize(
            videoResolutionConfiguration.current.size,
            withAspectRatio: videoAspect
        )
    }
    
    private func prepareEffects() {
        guard let videoEditorAsset = videoEditorService.videoAsset else {
            debugPrint("VideoEditorAsset is not configured!")
            return
        }
        let effectsProvider = EffectsProvider()
        
        // Add Color effect
        guard let colorEffectUrl = Bundle.main.url(forResource: "luts/japan", withExtension: "png") else {
            fatalError("Cannot find color effect! Please check if color effect exists")
        }
        effectApplicator.applyColorEffect(
            name: "Japan",
            lutUrl: colorEffectUrl,
            startTime: .zero,
            endTime: .zero,
            removeSameType: false,
            effectId: EffectIDs.colorEffectStartId + effectsProvider.generatedEffectId
        )
        
        // Add Visual VHS effect
        effectApplicator.applyVisualEffectApplicatorType(
            .vhs,
            startTime: .zero,
            endTime: .zero,
            removeSameType: false,
            effectId: EffectIDs.visualEffectStartId + effectsProvider.generatedEffectId
        )
        
        // Add Sticker effect
        let stickerEffect = effectsProvider.provideStickerEffect(duration: videoEditorAsset.composition.duration)
        effectApplicator.applyOverlayEffectType(
            .gif,
            effectInfo: stickerEffect
        )
        
        // Add Text effect
        let textEffect = effectsProvider.provideTextEffect(duration: videoEditorAsset.composition.duration)
        effectApplicator.applyOverlayEffectType(
            .text,
            effectInfo: textEffect
        )
        
        // Audio track
        let audioTrack = effectsProvider.provideMusicEffect()
        videoEditorService.videoAsset?.addMusicTrack(audioTrack)
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
