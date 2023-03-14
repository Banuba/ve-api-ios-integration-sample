//
//  PreviewImageViewController.swift
//  VEAPISample
//
//  Created by Andrey Sak on 3.03.23.
//

import UIKit

class PreviewImageViewController: UIViewController {
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])
        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(hideAction)
            )
        )
    }
    
    @objc func hideAction() {
        dismiss(animated: true)
    }
}
