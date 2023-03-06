//
//  ExportViewController.swift
//  VEAPISample
//
//  Created by Banuba on 13.12.22.
//

import UIKit
import YPImagePicker
import Photos
import AVKit

// Banuba Modules
import VideoEditor
import VEEffectsSDK
import VEExportSDK
import BanubaUtilities

class ExportViewController: UIViewController {
  
  @IBOutlet weak var startExportButton: UIButton!
  @IBOutlet weak var previewContainer: UIView!
  @IBOutlet weak var previewImageView: UIImageView!
  @IBOutlet weak var playVideoButton: UIButton!
  
  // Export progress controls
  @IBOutlet weak var stopExportButton: UIButton!
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  @IBOutlet weak var invalidTokenLabel: UILabel!
  
  private var cancelExportHandler: CancelExportHandler?
  
  private var exportedVideoUrl: URL?
  
  // MARK: - Banuba Services
  private var editor: VideoEditorService!
  private var exportSDK: VEExport!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupBanubaServices()
    activityIndicator.isHidden = true
  }
  
  private func setupBanubaServices() {
    guard let editor = VideoEditorService(token: AppDelegate.licenseToken) else {
      fatalError("The token is invalid. Please check if token contains all characters.")
    }
    
    self.editor = editor
    self.exportSDK = VEExport(videoEditorService: editor)
  }
}

// MARK: - Actions
extension ExportViewController {
  @IBAction func startExportAction(_ sender: Any) {
    previewImageView.image = nil
    exportedVideoUrl = nil
    playVideoButton.isHidden = true
    
    checkLicense {
      self.presentMediaPicker()
    }
  }
  
  @IBAction func stopExportAction(_ sender: Any) {
    cancelExportHandler?.cancel()
  }
  
  @IBAction func backAction(_ sender: Any) {
    cancelExportHandler?.cancel()
    navigationController?.dismiss(animated: true)
  }
  
  @IBAction func playVideoAction(_ sender: Any) {
    guard let exportedVideoUrl else {
      return
    }
    
    let player = AVPlayer(url: exportedVideoUrl)
    let playerController = AVPlayerViewController()
    playerController.player = player
    present(playerController, animated: true) {
        player.play()
    }
  }
  
  private func presentMediaPicker() {
    // Usage of YPImagePicker is for demonstration purposes.
    // You could use your own implementation of gallery or another third-party library.
    var config = YPImagePickerConfiguration()
    
    config.video.libraryTimeLimit = 600.0
    config.video.minimumTimeLimit = 0.3
    config.video.compression = AVAssetExportPresetPassthrough
    
    config.screens = [.library]
    config.showsVideoTrimmer = false
    
    config.library.mediaType = .video
    config.library.defaultMultipleSelection = true
    config.library.maxNumberOfItems = 10
    
    let galleryPicker = YPImagePicker(configuration: config)
    
    // Handler of YPImagePicker
    galleryPicker.didFinishPicking { [weak self] items, cancelled in
      guard !cancelled else {
        galleryPicker.dismiss(animated: true)
        return
      }
      
      // Compact YP items into PHAsset set
      let videoUrls: [URL] = items.compactMap { item in
        switch item {
        case .video(v: let videoItem):
          return videoItem.url
        default:
          return nil
        }
      }
      
      galleryPicker.dismiss(animated: true) {
        self?.exportVideo(videoUrls: videoUrls)
      }
    }
    
    present(galleryPicker, animated: true)
  }
}

extension ExportViewController {
  private func checkLicense(completion: @escaping () -> Void) {
    editor.getLicenseState(completion: { [weak self] isValid in
      self?.invalidTokenLabel.isHidden = isValid
      if isValid {
        completion()
      }
    })
  }
    
  private func exportVideo(videoUrls: [URL]) {
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
      videoResolutionConfiguration: Configs.resolutionConfig
    )

    // Set current video asset to video editor service
    editor.setCurrentAsset(videoEditorAsset)
    
    let effectsApplyer = EffectsApplyer(editor: editor)

    // Apply original track rotation for each asset track
    videoEditorAsset.tracksInfo.forEach { assetTrack in
      let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(assetTrack)
      effectsApplyer.applyTransformEffect(
        start: assetTrack.timeRangeInGlobal.start,
        end: assetTrack.timeRangeInGlobal.end,
        rotation: rotation
      )
    }
    
    let effectsProvider = EffectsProvider(totalVideoDuration: videoEditorAsset.composition.duration)
    effectsProvider.provideAllEffects().forEach { effect in
      effectsApplyer.applyEffect(effect)
    }
    
    // Get result file url
    let exportedVideoUrl = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.mov")
    if FileManager.default.fileExists(atPath: exportedVideoUrl.path) {
      try? FileManager.default.removeItem(at: exportedVideoUrl)
    }
    
    // Export settings
    let exportVideoInfo = ExportVideoInfo(
      resolution: .fullHd1080,
      useHEVCCodecIfPossible: true
    )
    
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
    
    startExportAnimation()
    cancelExportHandler = exportSDK.exportVideo(
      to: exportedVideoUrl,
      using: exportVideoInfo,
      watermarkFilterModel: nil,
      exportProgress: { [weak self] progress in
        DispatchQueue.main.async { self?.progressView.progress = Float(progress) }
      }
    ) { [weak self] success, error in
      self?.cancelExportHandler = nil
      
      DispatchQueue.main.async {
        self?.stopExportAnimation()
        self?.playVideoButton.isHidden = success == false
      }
      
      if error?.isCancelled == true {
        return
      }
      
      if let error {
        print(error.localizedDescription as Any)
        return
      }
      
      self?.exportedVideoUrl = exportedVideoUrl
      self?.setupVideoPreview(videoUrl: exportedVideoUrl)
    }
  }
  
  private func setupVideoPreview(videoUrl: URL) {
    let asset = AVURLAsset(url: videoUrl)
    let assetImageGenerator = AVAssetImageGenerator(asset: asset)
    assetImageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { [weak self] _, preview, _, _, _ in
      DispatchQueue.main.async {
        guard let preview else {
          return
        }
        let previewImage = UIImage(cgImage: preview)
        self?.previewImageView.image = previewImage
      }
    }
  }
}

// MARK: - Export progress helpers
extension ExportViewController {
  private func startExportAnimation() {
    setupUI(isExporting: true)
  }
  
  private func stopExportAnimation() {
    setupUI(isExporting: false)
  }
  
  private func setupUI(isExporting: Bool) {
    activityIndicator.isHidden = !isExporting
    if isExporting {
      activityIndicator.startAnimating()
    } else {
      activityIndicator.stopAnimating()
    }
    
    progressView.progress = .zero
    progressView.isHidden = !isExporting
    stopExportButton.isHidden = !isExporting
    
    startExportButton.isEnabled = !isExporting
  }
}
