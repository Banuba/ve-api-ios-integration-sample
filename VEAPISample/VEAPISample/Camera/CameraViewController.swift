//
//  ViewController.swift
//  VEAPISample
//
//  Created by Gleb Markin on 9.03.22.
//

import UIKit
import AVFoundation

import BanubaSdk
import VideoEditor

private struct Defaults {
    // MARK: - Video folder directory
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let videosDirectory = documentsDirectory.appendingPathComponent(videosDirectoryName)
    static let videosDirectoryName = "Videos"
    
    // MARK: - Min and Max duration from Camera
    static let minimumDuration = 3.0
    static let maximumDuration = 60.0
}

class CameraViewController: UIViewController {
    
    // MARK: - Effect view
    @IBOutlet weak var effectView: UIView!
    
    // MARK: - Control button
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    
    // MARK: - Camera effect buttons
    @IBOutlet weak var flashlightButton: UIButton!
    @IBOutlet weak var rotateCameraButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var maskButton: UIButton!
    @IBOutlet weak var beautyButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!
    
    // MARK: - Relevant recorded duration
    @IBOutlet weak var durationLabel: UILabel!
    
    // MARK: - Control button
    @IBOutlet var controlButtons: [UIButton]!
    
    // MARK: - FAR
    private var sdkManager = BanubaSdkManager()
    private let config = EffectPlayerConfiguration(renderMode: .video)
    private var effectPlayerView: EffectPlayerView?
    
    // MARK: - Current video sequence
    var videoSequence: VideoSequence?
    
    // MARK: - Video urls
    private var recordedVideos: [URL] = [] {
        didSet {
            // Hide buttons if videos doesn't exist
            guard recordedVideos.count > .zero else {
                galleryButton.isHidden = false
                nextButton.isHidden = true
                removeButton.isHidden = true
                return
            }
            galleryButton.isHidden = true
            nextButton.isHidden = false
            removeButton.isHidden = false
        }
    }
    
    // MARK: - Recording state
    var isRecording = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup effect player view with container frame
        setupEffectPlayerView()
        // Setup EffectPlayer with config instance
        sdkManager.setup(configuration: config)
        // Setup render size with portrait settings.
        setUpRenderSize()
        
        // Create default VideoSequence with choosen folder
        videoSequence = VideoSequence(folderURL: Defaults.videosDirectory)
        // Rotate to display back camera
        rotateCameraButtonTap(rotateCameraButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start camera streaming
        sdkManager.input.startCamera()
        // Start Effect Player to render mask effects
        sdkManager.startEffectPlayer()
        // Setup buttons style
        setupButtons()
    }
    
    deinit {
        sdkManager.destroyEffectPlayer()
    }
}

// MARK: - UI Helpers
extension CameraViewController {
    private func setupButtons() {
        // Corner radius
        nextButton.layer.cornerRadius = 10.0
    }
}

// MARK: - FAR helpers
extension CameraViewController {
    private func setUpRenderTarget() {
        // EffectPlayerView consist of CAEAGLLayer which we need set as render target for Effect Player
        guard let glLayer = effectPlayerView?.layer as? CAEAGLLayer else {
            return
        }
        // Setup rendet target from gl layer
        sdkManager.setRenderTarget(layer: glLayer, playerConfiguration: nil)
        // Start effect player after launching gl layer
        sdkManager.startEffectPlayer()
    }
    
    private func setupEffectPlayerView() {
        // Set EffectPlayerView frame the same as container view
        let preview = EffectPlayerView(frame: effectView.frame)
        effectView.addSubview(preview)
        effectPlayerView = preview
    }
    
    private func setUpRenderSize() {
        // Portrait setting for Effect Player condiguration
        config.orientation = .deg90
        config.renderSize = Configs.resolutionConfig.current.size
        // Disable rotation. Application is only contain portrait mode
        sdkManager.autoRotationEnabled = false
        setUpRenderTarget()
    }
}

// MARK: - Recording
extension CameraViewController {
    func recordVideo(_ shouldRecord: Bool) {
        // Disk capacity condition to avoid errors after recording if space isn't enought
        let hasSpace =  sdkManager.output?.hasDiskCapacityForRecording() ?? true
        // File url from videos directory
        let fileURL = Defaults.videosDirectory.appendingPathComponent("video\(recordedVideos.count).mp4")
        
        // Recording condition
        if shouldRecord && hasSpace {
            
            // Getting speed button title for following casting
            let speedTitle = speedButton.title(for: speedButton.state)
            // Relevant recording speed
            let speed = Double(speedTitle ?? "1.0") ?? 1.0
            
            // Already captured duration from all video items
            let capturedDuration = videoSequence?.totalDuration() ?? .zero
            // Remaining record time
            let elapsedTime = speed * (Defaults.maximumDuration - capturedDuration)
            // Minimum duration
            let minimumCapturedDuration = Defaults.minimumDuration * speed
            // Total duration for capturing service
            let totalDuration = max(elapsedTime, minimumCapturedDuration)
            
            // Disable audio capturing if mute button is selected
            if !muteButton.isSelected {
                sdkManager.input.startAudioCapturing()
            }
            
            // Start video capturing
            sdkManager.output?.startVideoCapturing(
                fileURL: fileURL,
                externalAudioConfiguration: nil,
                progress: { [weak self] time in
                    DispatchQueue.main.async {
                        // Change remaning time label with relevant progress
                        self?.durationLabel.text = String(Int(totalDuration - time.seconds))
                    }
                },
                didStart: { [weak self] in
                    DispatchQueue.main.async {
                        // Show remaining time label after capturing did start
                        self?.durationLabel.isHidden = false
                        // Hide control buttons while recording to avoid extra control usage
                        self?.controlButtons.forEach { button in
                            button.isHidden = true
                        }
                    }
                },
                periodicProgressTimeInterval: 0.1,
                boundaryTimes: [NSValue](),
                boundaryHandler: { _ in },
                totalDuration: totalDuration,
                // OutputConfiguration of ouput recording stream
                configuration: OutputConfiguration(
                    applyWatermark: true,
                    adjustDeviceOrientation: false,
                    mirrorFrontCamera: false,
                    useHEVCCodecIfPossible: false
                ),
                completion: { [weak self] (success, error) in
                    // Stop audio capturing if recording did finish
                    self?.sdkManager.input.stopAudioCapturing()
                    DispatchQueue.main.async {
                        // Return buttons to previous states
                        self?.durationLabel.isHidden = true
                        self?.controlButtons.forEach { button in
                            // Gallery button tag is 100
                            guard button.tag != 100 else { return }
                            button.isHidden = false
                        }
                    }
                    if let error = error {
                        // Proccess error
                        print(error)
                    } else {
                        // Add video url to array
                        self?.recordedVideos.append(fileURL)
                        // Add video to sequence
                        self?.videoSequence?.addVideo(
                            // URL
                            at: fileURL,
                            // Recording speed
                            speed: speed,
                            // is slideshow
                            isSlideShow: false,
                            // transition
                            transition: .normal
                        )
                        // Minimun duration condition to avoid small videos passing to editor screen. Depends on your business logic
                        let isMinimumDuration = (self?.videoSequence?.totalDuration() ?? .zero) < Defaults.minimumDuration
                        self?.nextButton.isEnabled = !isMinimumDuration
                    }
                }
            )
        } else {
            // Stop video capturing if isn't enought space or stop button was tapped
            sdkManager.output?.stopVideoCapturing(cancel: false)
        }
    }
    
    private func createSequencePath() -> URL {
        // Video path directory for storing session videos
        let name = UUID().uuidString
        return Defaults.videosDirectory.appendingPathComponent(name)
    }
}

// MARK: - Actions
extension CameraViewController {
    @IBAction func muteButtonDidTap(_ sender: UIButton) {
        // Change button icon with relevant state
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func maskButtonDidTap(_ sender: UIButton) {
        // Change button icon with relevant state
        beautyButton.isSelected = false
        sender.isSelected = !sender.isSelected
        
        // Apply or disable predefined mask with Effect Player by effect name
        let name = sender.isSelected ? "UnluckyWitch" : ""
        _ = sdkManager.loadEffect(name, synchronous: false)
    }
    
    @IBAction func rotateCameraButtonTap(_ sender: UIButton) {
        // Toggle camera from front to back or vice versa.
        sdkManager.input.toggleCamera { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Front camera doesn't containt flash functionality during capturing video
                self.flashlightButton.isEnabled = !self.sdkManager.input.isFrontCamera
                sender.isSelected = self.sdkManager.input.isFrontCamera
            }
        }
    }
    
    @IBAction func beautyButtonDidTap(_ sender: UIButton) {
        // Change button icon with relevant state
        maskButton.isSelected = false
        sender.isSelected = !sender.isSelected
        
        // Apply or disable predefined mask with Effect Player by effect name
        let name = sender.isSelected ? "BeautyEffects" : ""
        _ = sdkManager.loadEffect(name, synchronous: false)
    }
    
    @IBAction func flashlightButtonDidTap(_ sender: UIButton) {
        // Chang flash state
        let torchMode = sdkManager.input.toggleTorch()
        let isOn = torchMode == .on
        sender.isSelected = isOn
    }
    
    @IBAction func nextButtonDidTap(_ sender: UIButton) {
        // Check if captured duration is enought for going forward
        let capturedDuration = videoSequence?.totalDuration() ?? .zero
        guard capturedDuration >= Defaults.minimumDuration else {
            return
        }
        // Create video asset for CoreAPI usage
        let videoEditorAsset = VideoEditorAsset(
            sequence: videoSequence!,
            isGalleryAssets: false,
            isSlideShow: false,
            // Resolution configuration describes devices classes
            videoResolutionConfiguration: Configs.resolutionConfig
        )
        // Set current asset sequence to the CoreAPI
        CoreAPI.shared.coreAPI.setCurrentAsset(videoEditorAsset)
        
        // Navigate to Editor screen
        let editorController = UIStoryboard(
            name: "Main",
            bundle: .main
        ).instantiateViewController(
            withIdentifier: "EditorViewController"
        )
        navigationController?.pushViewController(
            editorController,
            animated: true
        )
    }
    
    @IBAction func galleryButtonDidTap(_ sender: UIButton) {
        // Navigate to Gallery screen
        let galleryController = GalleryViewController()
        navigationController?.pushViewController(galleryController, animated: true)
    }
    
    @IBAction func speedButtonDidTap(_ sender: UIButton) {
        // Change button icon with relevant state
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func removeButtonDidTap(_ sender: UIButton) {
        // Remove video urls
        recordedVideos.removeAll()
        // Remove videos from sequence file manager folder
        videoSequence?.videos.forEach { video in
            // Completely delete video
            videoSequence?.deleteVideo(video)
        }
    }
    
    @IBAction func recordButtonTouchDown(_ sender: UIButton) {
        // Start recording video
        recordVideo(true)
    }
    
    @IBAction func recordButtonTouchUp(_ sender: UIButton) {
        // Stop recording video
        recordVideo(false)
    }
}
