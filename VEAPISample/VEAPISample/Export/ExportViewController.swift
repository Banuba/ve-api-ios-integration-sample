//
//  ExportViewController.swift
//  VEAPISample
//
//  Created by Banuba on 13.12.22.
//

import UIKit
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
    
    // Stores cancel export handler
    private var cancelExportHandler: CancelExportHandler?
    
    // URL to result video
    private var resultVideoUrl: URL?
    
    // Manager that handles export video flow
    private var exportManager: ExportManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exportManager = ExportManager(videoEditorModule: AppDelegate.videoEditorModule)
        
        invalidateUIState(isExporting: false)
    }

    // MARK: - Actions
    
    @IBAction func startExportAction(_ sender: Any) {
        previewImageView.image = nil
        resultVideoUrl = nil
        playVideoButton.isHidden = true
        
        pickVideo { [weak self] videoUrls in
            guard let videoUrls else { return }
            self?.exportVideo(with: videoUrls)
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
        
        demoPlayExportedVideo(exportedVideoUrl: resultVideoUrl)
    }
    
    private func exportVideo(with selectedVideoUrls: [URL]) {
        invalidateUIState(isExporting: true)
        
        exportManager.setupVideoContent(with: selectedVideoUrls)
        
        cancelExportHandler = exportManager.exportVideo(
            progressCallback: { [weak self] progress in
                DispatchQueue.main.async { self?.progressView.progress = progress }
            },
            completion: { [weak self] resultVideoUrl, success, error in
                DispatchQueue.main.async {
                    self?.invalidateUIState(isExporting: false)
                    self?.playVideoButton.isHidden = success == false
                }
                
                guard let resultVideoUrl else { return }
                
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
    
    private func invalidateUIState(isExporting: Bool) {
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
    
    private func demoPlayExportedVideo(exportedVideoUrl: URL) {
        let player = AVPlayer(url: exportedVideoUrl)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
}
