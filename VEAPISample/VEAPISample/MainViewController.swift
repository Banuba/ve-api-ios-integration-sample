//
//  MainViewController.swift
//  VEAPISample
//
//  Created by Andrei Sak on 16.03.23.
//

import UIKit

import BanubaVideoEditorCore

class MainViewController: UIViewController {
    
    @IBOutlet weak var invalidTokenLabel: UILabel!
    @IBOutlet weak var playbackFlowButton: UIButton!
    @IBOutlet weak var exportFlowButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable flow buttons until license check will be completed
        playbackFlowButton.isEnabled = false
        exportFlowButton.isEnabled = false
        
        // Check license state. Maybe valid or unvalid
        let editor = AppDelegate.videoEditorModule.editor
        editor.getLicenseState(completion: { [weak self] isValid in
            self?.invalidTokenLabel.isHidden = isValid
            self?.playbackFlowButton.isEnabled = isValid
            self?.exportFlowButton.isEnabled = isValid
        })
    }
}
