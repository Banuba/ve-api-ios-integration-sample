import AVFoundation
import BanubaUtilities
import VEPlaybackSDK
import VideoEditor
import VEEffectsSDK

class PlaybackManager: VideoEditorPlayerDelegate {
    
    private(set) weak var playbackView: VideoPlayableView?
    
    // Player progress callback. You can use it to track player position
    var progressCallback: ((_ progress: Float) -> Void)?
    
    var player: VideoEditorPlayable? { playbackView?.videoEditorPlayer }
    
    var currentPlayerPostion: CMTime { playbackView?.videoEditorPlayer?.currentTime ?? .zero }
    
    var totalVideoDuration: CMTime { videoEditorService.videoAsset?.composition.duration ?? .zero }
    
    var isPlaying: Bool { player?.isPlaying ?? false}
    
    // Video editor service stores resulted video asset and applied effects
    private var videoEditorService: VideoEditorService!
     
    private var playbackSDK: VEPlayback!

    private let effectsProvider: EffectsProvider = EffectsProvider()
    
    private let videoResolutionConfiguration: VideoResolutionConfiguration
    private var videoSequence: VideoSequence?
    
    private let effectApplicator: EffectApplicator
    
    private var currentSpeedEffectRapidId: UInt = 0
    private var currentSpeedEffectSlowMoId: UInt = 0
    
    private var currentSpeedEffectRapidUuid: UUID?
    private var currentSpeedEffectSlowMoUuid: UUID?
    
    private var currentAudioTrack : MediaTrack? = nil
    
    init(videoEditorModule: VideoEditorApiModule) {
        self.videoEditorService = videoEditorModule.editor
        self.videoResolutionConfiguration = videoEditorModule.videoResolutionConfiguration
        self.playbackSDK = VEPlayback(videoEditorService: videoEditorService)
        
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
    
    /// Adds video content for playback
    func addVideoContent(with videoUrls: [URL]) {
        // Create videoSequence by provided video urls
        let videoSequence = createVideoSequence(with: videoUrls)
        self.videoSequence = videoSequence
        
        // Create VideoEditorAsset from relevant sequence
        // VideoEditorAsset is entity of VideoEditor used for plaback
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
    
    /// Provides video player preview
    func setSurfaceView(playerContainerView: UIView!) {
        let playbackView = playbackSDK.getPlayableView(delegate: self)
        self.playbackView = playbackView
        
        playerContainerView.addSubview(playbackView)
    }
    
    /// Sets video volume
    func setVideoVolume(_ volume: Float) {
        if let player {
            videoEditorService.setVideoVolume(volume, to: player)
        }
    }
    
    /// Returns screenshot if possible
    func takeScreenshot() -> UIImage? {
        guard let asset = videoEditorService.asset,
              let firstTrack = videoEditorService.videoAsset?.tracksInfo.first else {
            return nil
        }
        let previewExtractor = PreviewExtractor(
            asset: asset,
            thumbnailHeight: UIScreen.main.bounds.height
        )
        
        guard let cgImage = previewExtractor.extractPreview(at: currentPlayerPostion)?.cgImage else {
            print("Extracting preview failed")
            return nil
        }
        
        let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(firstTrack)
        let imageRotation = UIImage.orientation(byRotation: rotation)
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: imageRotation)
    }
    
    // MARK: - Playback managment
    
    func play(loop: Bool) {
        player?.play(loop: loop, fixedSpeed: false)
    }
    
    func pause() {
        player?.pause()
    }
    
    func seek(to time: CMTime) {
        let playbackRange = CMTimeRange(start: .zero, duration: totalVideoDuration)
        
        var seekTime: CMTime = .zero
        
        if playbackRange.containsTime(time) {
            seekTime = time
        }
        player?.seek(to: seekTime)
    }
    
    
    // Pauses player manager tracking player progress
    func stopTrackingPlayerProgress() {
        player?.playerDelegate = nil
    }
    
    // Resumes player manager tracking player progress
    func startTrackingPlayerProgress() {
        player?.playerDelegate = self
    }
    
    func applyColorEffect() {
        guard let colorEffectUrl = Bundle.main.url(forResource: "luts/japan", withExtension: "png") else {
            fatalError("Cannot find color effect! Please check if color effect exists")
        }
        
        effectApplicator.applyColorEffect(
            name: "Japan",
            lutUrl: colorEffectUrl,
            startTime: .zero,
            endTime: totalVideoDuration,
            removeSameType: false,
            effectId: EffectIDs.colorEffectStartId + effectsProvider.generatedEffectId
        )
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoColorEffect() {
        videoEditorService.undoLast(type: .color)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func applyMaskEffect() {
        let maskName = "AsaiLines"
        let maskEffect = effectsProvider.provideMaskEffect(withName: maskName)
        
        // Setup Banuba Mask Renderer
        // This operation can be time consuming
        BanubaMaskRenderer.loadEffectPath(maskEffect.path)
        
        videoEditorService.applyEffect(
            effectModel: maskEffect,
            uuid: effectsProvider.generatedEffectUuid,
            start: .zero,
            end: totalVideoDuration,
            removeSameType: true,
            isAutoCutEffect: false
        )
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoMaskEffect() {
        videoEditorService.undoAll(type: .mask)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func applyFXEffect() {
        effectApplicator.applyVisualEffectApplicatorType(
            .vhs,
            startTime: .zero,
            endTime: totalVideoDuration,
            removeSameType: false,
            effectId: EffectIDs.visualEffectStartId + effectsProvider.generatedEffectId
        )
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoFXEffect() {
        videoEditorService.undoLast(type: .visual)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func applyRapidSpeedEffect() {
        currentSpeedEffectRapidId = EffectIDs.speedEffectStartId + effectsProvider.generatedEffectId
        currentSpeedEffectRapidUuid = UUID(uuidString: effectsProvider.generatedEffectUuid)
        
        effectApplicator.applySpeedEffectType(
            .rapid,
            startTime: .zero,
            endTime: totalVideoDuration,
            removeSameType: false,
            effectId: currentSpeedEffectRapidId
        )
        
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoRapidSpeedEffect() {
        undoEffect(withId: currentSpeedEffectRapidUuid)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func applySlowoSpeedEffect() {
        currentSpeedEffectSlowMoId = EffectIDs.speedEffectStartId + effectsProvider.generatedEffectId
        currentSpeedEffectSlowMoUuid = UUID(uuidString: effectsProvider.generatedEffectUuid)
        
        effectApplicator.applySpeedEffectType(
            .slowmo,
            startTime: .zero,
            endTime: totalVideoDuration,
            removeSameType: false,
            effectId: currentSpeedEffectSlowMoId
        )
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoSlowmoSpeedEffect() {
        undoEffect(withId: currentSpeedEffectSlowMoUuid)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func applyTextEffect() {
        let textEffect = effectsProvider.provideTextEffect(duration: totalVideoDuration)
        
        effectApplicator.applyOverlayEffectType(
            .text,
            effectInfo: textEffect
        )
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoTextEffect() {
        undoAll(type: .text)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func applyStickerEffect() {
        let stickerEffect = effectsProvider.provideStickerEffect(duration: totalVideoDuration)
        
        effectApplicator.applyOverlayEffectType(
            .gif,
            effectInfo: stickerEffect
        )
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoStickerEffect() {
        undoAll(type: .gif)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func applyMusicEffect() {
        currentAudioTrack = effectsProvider.provideMusicEffect()
        
        videoEditorService.videoAsset?.addMusicTrack(currentAudioTrack!)
        
        // Get new instance of player to playback music track
        reloadPlayerAtCurrentTime()
    }
    
    func undoMusicEffect() {
        if let audioId = currentAudioTrack?.id {
            videoEditorService.videoAsset?.removeMusic(trackId: audioId)
            // Get new instance of player to playback music track
            reloadPlayerAtCurrentTime()
        }
    }
    
    /// Apply transition effect for all videos
    func applyTransitionEffect() {
        guard let videoTracks = videoEditorService.videoAsset?.tracksInfo, videoTracks.count > 1 else {
            Logger.logError("Transition effect can be applied between at least 2 videos")
            return
        }
        /// This is const value used in transition shaders
        let transitionDuration = CMTime(seconds: 0.5, preferredTimescale: .default)
        /// Transition applies for 2 video tracks. The half on the first one the second half on the second video
        let transitionDurationOnVideoTrack = CMTime(
            seconds: transitionDuration.seconds / 2.0,
            preferredTimescale: .default
        )
        videoTracks
            // Video should be more than or equal of half of transition duration
            .filter { $0.timeRangeInGlobal.duration >= transitionDurationOnVideoTrack }
            // Transition for first track should not be applied
            .dropFirst()
            .forEach { videoTrack in
                // All available transition listed in enum TransitionType
                let transitionEffectType: TransitionType = .scrollLeft
                let transitionEffectInfo = TransitionEffectInfo(
                    type: transitionEffectType,
                    start: videoTrack.timeRangeInGlobal.start - transitionDurationOnVideoTrack,
                    end: videoTrack.timeRangeInGlobal.start + transitionDurationOnVideoTrack
                )
                effectApplicator.applyTransitionEffect(
                    type: transitionEffectType,
                    effectInfo: transitionEffectInfo
                )
            }
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoTransitionEffect() {
        undoAll(type: .transition)
    }
    
    func applyBlurEffect() {
        let videoSize = player?.playerItem?.presentationSize ?? .zero
        // Place blur in center of video
        
        effectApplicator.applyOverlayEffectType(
            .blur(
                drawableFigure: .circle,
                coordinates: BlurCoordinateParams(
                    center: CGPoint(x: videoSize.width / 2.0, y: videoSize.height / 2.0),
                    width: videoSize.width,
                    height: videoSize.height,
                    radius: videoSize.width * 0.2
                )
            ),
            effectInfo: VideoEditorEffectInfo(
                uuid: effectsProvider.generatedEffectUuid,
                image: nil,
                relativeScreenPoints: nil,
                start: .zero,
                end: totalVideoDuration
            )
        )
        
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    func undoBlurEffect() {
        undoAll(type: .blur)
        player?.reloadPreview(shouldAutoStart: isPlaying)
    }
    
    // MARK: - VideoEditorPlayerDelegate
    func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime) {
        let durationSeconds = totalVideoDuration.seconds
        
        if durationSeconds == 0 {
            progressCallback?(Float(0))
        } else {
            progressCallback?(Float(time.seconds / durationSeconds))
        }
    }
    
    /// Called when player reaches end of video content
    func playerDidEndPlaying(_ player: VideoEditorPlayable) {
        print("End of video content")
    }
    
    // MARK: - Private helpers
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
                crop: nil,
                cropFrame: nil,
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
    
    private func reloadPlayerAtCurrentTime() {
        let currentTime = self.currentPlayerPostion
        let isPlaying = self.isPlaying
        // Get new instance of player to playback music track
        reloadPlayer()
        // Seek new player to current time
        seek(to: currentTime)
        if isPlaying {
            play(loop: true)
        }
    }
    
    private func reloadPlayer() {
        playbackView?.setPlayer(nil, isThumbnailNeeded: false)
        let player = playbackSDK.getPlayer(forExternalAsset: nil, delegate: self)
        // Setup new player
        playbackView?.setPlayer(player, isThumbnailNeeded: false)
    }
    
    private func undoAll(type: VideoEditor.EditorEffectType) {
        videoEditorService.undoAll(type: type)
    }
    
    /// Undo effect with specific id
    private func undoEffect(withId uuid: UUID?) {
        guard let uuid else { return }
        videoEditorService.undoEffect(uuid: uuid.uuidString)
    }
}
