import AVFoundation
import BanubaUtilities
import VEPlaybackSDK
import VideoEditor

class PlaybackManager: VideoEditorPlayerDelegate {
    private struct Effects {
        static var rapid: Effect?
        static var slowmo: Effect?
        static var trackUrl: URL?
        static var trackId: CMPersistentTrackID?
    }
    
    // MARK: - VideoPlayableView
    private(set) weak var playableView: VideoPlayableView?
    
    // Player progress callback. You can use it to track player position
    var progressCallback: ((_ progress: Float) -> Void)?
    
    
    var player: VideoEditorPlayable? { playableView?.videoEditorPlayer }
    var currentPostionTime: CMTime { playableView?.videoEditorPlayer?.currentTimeInCMTime ?? .zero }
    var videoDuration: CMTime { editor.videoAsset?.composition.duration ?? .zero }
    var isPlaying: Bool { player?.isPlaying ?? false}
    
    // MARK: - Banuba Services used for playback
    // Video editor service stores resulted video asset and applied effects
    private var editor: VideoEditorService!
    // Playback sdk provides playback view for previewing decorated video
    private var playbackSDK: VEPlayback!
    /// Provides effects
    private let effectsProvider: EffectsProvider!
    // Applies and cancels effects
    private let effectsManager: EffectsManager!
    
    private let videoResolutionConfiguration: VideoResolutionConfiguration
    private var videoSequence: VideoSequence?
    
    init(videoEditorModule: VideoEditorModule) {
        editor = videoEditorModule.editor
        videoResolutionConfiguration = videoEditorModule.videoResolutionConfiguration
        
        effectsManager = EffectsManager(editor: editor)
        effectsProvider = EffectsProvider()
        
        playbackSDK = VEPlayback(videoEditorService: editor)
    }
    
    deinit {
        guard let videoSequence else { return }
        // Clean up video sequence resources
        try? FileManager.default.removeItem(at: videoSequence.folderURL)
    }
    
    /// Adds video content for playback
    func addVideoContent(with videoUrls: [URL]) {
        // Create videoSequence of video by provided video urls
        // VideoSequence entity helps to manage video in sequence and stores additional info
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
        editor.setCurrentAsset(videoEditorAsset)
        
        // Apply original video rotation as effect
        adjustVideoEditorAssetTracksRotation(videoEditorAsset)
        
        // Setup preview render size
        setupRenderSize(videoSequence: videoSequence)
        
        // Setup effects provider video duration
        effectsProvider.totalVideoDuration = videoEditorAsset.composition.duration
    }
    
    /// Provides video player preview
    func setSurfaceView(playerContainerView: UIView!) {
        let playableView = playbackSDK.getPlayableView(delegate: self)
        self.playableView = playableView
        
        playerContainerView.addSubview(playableView)
    }
    
    /// Sets video volume
    func setVideoVolume(_ volume: Float) {
        editor.setAudioTrackVolume(volume, to: player)
    }
    
    /// Returns screenshot if possible
    func takeScreenshot() -> UIImage? {
        guard let asset = editor.asset,
              let firstTrack = editor.videoAsset?.tracksInfo.first else {
            return nil
        }
        let previewExtractor = PreviewExtractor(
            asset: asset,
            thumbnailHeight: UIScreen.main.bounds.height
        )
        
        guard let cgImage = previewExtractor.extractPreview(at: currentPostionTime)?.cgImage else {
            print("Extracting preview failed")
            return nil
        }
        
        let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(firstTrack)
        let imageRotation = UIImage.orientation(byRotation: rotation)
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: imageRotation)
    }
    
    // MARK: - Playback managment
    
    func play(loop: Bool) {
        player?.startPlay(loop: loop, fixedSpeed: false)
    }
    
    func pause() {
        player?.stopPlay()
    }
    
    func seek(to time: CMTime) {
        let playbackRange = CMTimeRange(start: .zero, duration: videoDuration)
        
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
    
    // MARK: - Effects managment
    
    func applyMaskEffect() {
        let maskEffect = effectsProvider.provideMaskEffect(withName: "AsaiLines")
        effectsManager.applyMaskEffect(maskEffect)
        reloadPreview()
    }
    
    func undoMaskEffect() {
        effectsManager.undoMaskEffect()
        reloadPreview()
    }
    
    func applyFXEffect() {
        let vhs = effectsProvider.provideVisualEffect(type: .vhs)
        effectsManager.applyVisualEffect(vhs)
        reloadPreview()
    }
    
    func undoFXEffect() {
        effectsManager.undoVisualEffect()
        reloadPreview()
    }
    
    func applyRapidSpeedEffect() {
        Effects.rapid = effectsProvider.provideSpeedEffect(type: .rapid)
        effectsManager.applySpeedEffect(Effects.rapid!)
        reloadPreview()
    }
    
    func undoRapidSpeedEffect() {
        effectsManager.undoEffect(withId: Effects.rapid!.id)
        reloadPreview()
        Effects.rapid = nil
    }
    
    func applySlowoSpeedEffect() {
        Effects.slowmo = effectsProvider.provideSpeedEffect(type: .slowmo)
        effectsManager.applySpeedEffect(Effects.slowmo!)
        reloadPreview()
    }
    
    func undoSlowmoSpeedEffect() {
        effectsManager.undoEffect(withId: Effects.slowmo!.id)
        reloadPreview()
        Effects.slowmo = nil
    }
    
    func applyTextEffect() {
        let text = effectsProvider.provideOverlayEffect(type: .text)
        effectsManager.applyOverlayEffect(text)
        reloadPreview()
    }
    
    func undoTextEffect() {
        effectsManager.undoAll(type: .text)
        reloadPreview()
    }
    
    func applyStickerEffect() {
        let sticker = effectsProvider.provideOverlayEffect(type: .gif)
        effectsManager.applyOverlayEffect(sticker)
        reloadPreview()
    }
    
    func undoStickerEffect() {
        effectsManager.undoAll(type: .gif)
        reloadPreview()
    }
    
    func applyColorEffect() {
        let color = effectsProvider.provideJapanColorEffect()
        effectsManager.applyColorEffect(color)
        reloadPreview()
    }
    
    func undoColorEffect() {
        effectsManager.undoColorEffect()
        reloadPreview()
    }
    
    func applyMusicEffect() {
        let musicEffect = effectsProvider.provideMusicEffect()
        
        Effects.trackId = CMPersistentTrackID(musicEffect.id)
        Effects.trackUrl = musicEffect.additionalInfo[Effect.AdditionalInfoKey.url] as? URL
        
        effectsManager.applyMusicEffect(musicEffect)
        // Get new instance of player to playback music track
        reloadPlayerAtCurrentTime()
    }
    
    func undoMusicEffect() {
        effectsManager.undoMusicEffect(
            id: Effects.trackId!,
            url: Effects.trackUrl!
        )
        // Get new instance of player to playback music track
        reloadPlayerAtCurrentTime()
    }
    
    func applyCustomEffect() {
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
        reloadPreview()
    }
    
    func undoCustomEffect() {
        effectsManager.undoAll(type: .blur)
        reloadPreview()
    }
    
    // MARK: - VideoEditorPlayerDelegate
    func playerPlaysFrame(_ player: VideoEditorPlayable, atTime time: CMTime) {
        let progress = time.seconds / videoDuration.seconds
        progressCallback?(Float(progress))
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
    
    private func reloadPreview() {
        let shouldAutoStart = isPlaying
        player?.reloadComposition(shouldAutoStart: shouldAutoStart)
    }
    
    private func reloadPlayerAtCurrentTime() {
        let currentTime = self.currentPostionTime
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
        playableView?.setPlayer(nil, isThumbnailNeeded: false)
        let player = playbackSDK.getPlayer(forExternalAsset: nil, delegate: self)
        // Setup new player
        playableView?.setPlayer(player, isThumbnailNeeded: false)
    }
}
