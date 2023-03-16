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
import VEExportSDK

class ExportViewController: UIViewController {
    
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var playVideoButton: UIButton!
    @IBOutlet weak var startExportButton: UIButton!
    @IBOutlet weak var stopExportButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var invalidTokenLabel: UILabel!
    
    // Stores cancel export handler
    private var cancelExportHandler: CancelExportHandler?
    
    // URL to result video
    private var resultVideoUrl: URL?
    
    // Manager that handles export video flow
    private var exportManager: ExportManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exportManager = ExportManager(videoEditorModule: AppDelegate.videoEditorModule)
        
        setupUI(isExporting: false)
    }

    // MARK: - Actions
    
    @IBAction func startExportAction(_ sender: Any) {
        previewImageView.image = nil
        resultVideoUrl = nil
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
        guard let resultVideoUrl else {
            // Nothing to play
            return
        }
        
        let player = AVPlayer(url: resultVideoUrl)
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
                self?.exportVideo(with: videoUrls)
            }
        }
        
        present(galleryPicker, animated: true)
    }
    
    private func exportVideo(with selectedVideoUrls: [URL]) {
        startExportAnimation()
        
        exportManager.setupVideoContent(with: selectedVideoUrls)
        
        // Prepare result video url
        let resultVideoUrl = FileManager.default.temporaryDirectory.appendingPathComponent("tmp.mov")
        if FileManager.default.fileExists(atPath: resultVideoUrl.path) {
            try? FileManager.default.removeItem(at: resultVideoUrl)
        }
        
        cancelExportHandler = exportManager.exportVideo(
            to: resultVideoUrl,
            progressCallback: { [weak self] progress in
                DispatchQueue.main.async { self?.progressView.progress = progress }
            },
            completion: { [weak self] success, error in
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
                
                self?.resultVideoUrl = resultVideoUrl
                self?.setupVideoPreview(resultVideoUrl: resultVideoUrl)
            }
        )
    }
    
    private func setupVideoPreview(resultVideoUrl: URL) {
        guard let preview = exportManager.takeScreenshot(of: AVURLAsset(url: resultVideoUrl), at: .zero) else {
            return
        }
        DispatchQueue.main.async {
            self.previewImageView.image = preview
        }
    }
    
    // MARK: - Export progress helpers
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

    // MARK: - Check license helpers
    private func checkLicense(completion: @escaping () -> Void) {
        exportManager.editor.getLicenseState(completion: { [weak self] isValid in
            self?.invalidTokenLabel.isHidden = isValid
            if isValid {
                completion()
            }
        })
    }
}
