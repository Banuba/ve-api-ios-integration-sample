//
//  PickVideoViewController.swift
//  VEAPISample
//
//  Created by Banuba on 2.03.23.
//

import UIKit
import YPImagePicker
import AVFoundation

import VideoEditor

class PickVideoViewController: UIViewController {

    @IBAction func pickVideoAction(_ sender: UIButton) {
        pickVideo { [weak self] videoUrls in
            guard let videoUrls else { return }
            self?.presentPlaybackViewController(with: videoUrls)
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.dismiss(animated: true)
    }
    
    func presentPlaybackViewController(with videoUrls: [URL]) {
        performSegue(
            withIdentifier: "showVideoEditorPlayback",
            sender: videoUrls
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == "showVideoEditorPlayback",
            let videoUrls = sender as? [URL],
            let playbackVC = segue.destination as? PlaybackViewController
        else {
            super.prepare(for: segue, sender: sender)
            return
        }
        // Pass parameters to playback view controller
        playbackVC.selectedVideoContent = videoUrls
    }
}
