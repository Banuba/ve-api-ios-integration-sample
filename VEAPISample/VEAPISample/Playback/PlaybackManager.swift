import AVFoundation
import BanubaUtilities
import VEPlaybackSDK
import VideoEditor

class PlaybackManager {
    // MARK: - VideoPlayableView
    private(set) weak var playableView: VideoPlayableView?
    
    let effectsProvider: EffectsProvider!
    let effectsManager: EffectsManager!
    
    // MARK: - Playback helpers
    var player: VideoEditorPlayable? { playableView?.videoEditorPlayer }
    var currentTime: CMTime { playableView?.videoEditorPlayer?.currentTimeInCMTime ?? .zero }
    var videoDuration: CMTime { editor.videoAsset?.composition.duration ?? .zero }
    
    // MARK: - Banuba Services used for playback
    // Video editor service stores resulted video asset and applied effects
    var editor: VideoEditorService!
    // Playback sdk provides playback view for previewing decorated video
    var playbackSDK: VEPlayback!
    
    init(videoEditorModule: VideoEditorModule, videoUrls: [URL]) {
        editor = videoEditorModule.editor
        
        effectsManager = EffectsManager(editor: editor)
        effectsProvider = EffectsProvider()
        
        playbackSDK = VEPlayback(videoEditorService: editor)
        
        // Configure video editor service with video urls. Video must be downloaded
        setupVideoEditor(
            with: videoUrls,
            videoResolutionConfiguration: videoEditorModule.videoResolutionConfiguration
        )
        
        // Setup effects provider video duration
        effectsProvider.totalVideoDuration = videoDuration
    }
    
    func providePlaybackView(delegate: VideoEditorPlayerDelegate) -> VideoPlayableView {
        let playableView = playbackSDK.getPlayableView(delegate: delegate)
        self.playableView = playableView
        return playableView
    }
    
    func setVideoVolume(_ volume: Float) {
        editor.setAudioTrackVolume(volume, to: player)
    }
    
    func reloadPreview(shouldAutoStart: Bool) {
        player?.reloadComposition(shouldAutoStart: shouldAutoStart)
    }
    
    func reloadPlayer(delegate: VideoEditorPlayerDelegate) {
        // Get new instance of player to playback music track
        let player = playbackSDK.getPlayer(forExternalAsset: nil, delegate: delegate)
        // Setup new player
        playableView?.setPlayer(player, isThumbnailNeeded: false)
    }
    
    func takeScreenshot() -> UIImage? {
        guard let asset = editor.asset,
              let firstTrack = editor.videoAsset?.tracksInfo.first else {
            return nil
        }
        let previewExtractor = PreviewExtractor(
            asset: asset,
            thumbnailHeight: UIScreen.main.bounds.height
        )
        
        guard let cgImage = previewExtractor.extractPreview(at: currentTime)?.cgImage else {
            print("Extracting preview failed")
            return nil
        }
        
        let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(firstTrack)
        let imageRotation = UIImage.orientation(byRotation: rotation)
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: imageRotation)
    }
    
    /// Setup current video editor service for playback
    private func setupVideoEditor(
        with videoUrls: [URL],
        videoResolutionConfiguration: VideoResolutionConfiguration
    ) {
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
            videoResolutionConfiguration: videoResolutionConfiguration
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
}
