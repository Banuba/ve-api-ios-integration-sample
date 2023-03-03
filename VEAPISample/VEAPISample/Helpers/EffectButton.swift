//
//  EffectButton.swift
//  VEAPISample
//
//  Created by Andrey Sak on 2.03.23.
//

import UIKit

class EffectButton: UIButton {
  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected ? .systemPink : .lightGray
    }
  }
  
  override func draw(_ rect: CGRect) {
    super.draw(rect)
    sharedInit()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    sharedInit()
  }
  
  private func sharedInit() {
    layer.masksToBounds = true
    layer.cornerRadius = bounds.height / 2.0
    setTitleColor(.white, for: .selected)
    setTitleColor(.black, for: .normal)
  }
}
