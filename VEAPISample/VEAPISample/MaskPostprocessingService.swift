//
//  MaskPostProcessService.swift
//  VEAPISample
//
//  Created by Gleb Markin on 2/25/21
//

import Foundation
import BanubaVideoEditorCore
import BNBSdkCore
import BNBSdkApi

// MARK: - MaskPostprocessingService
@objc public class MaskPostprocessingService: NSObject {
  // MARK: - Private properties
  private let renderQueue = DispatchQueue(label: "com.banuba.video-editor.mask-postprocess-rendering", qos: .userInitiated)
  private var ep: BNBOffscreenEffectPlayer?
  private var renderSize: CGSize
  private let isMirrored = ObjCBool(false)
  private let needAlphaInOutput = ObjCBool(true)
  private let overrideOutputToBGRA = ObjCBool(true)
  private let shouldOutputTexture = ObjCBool(false)
  
  /// MaskPostprocessingService constructor
  /// - Parameters:
  ///   - renderSize: setup render size
  @objc public init(renderSize: CGSize) {
    self.renderSize = renderSize
    
    super.init()
    
    renderQueue.sync(flags: .barrier) { [weak self] in
      self?.initPlayer()
    }
    
    NotificationCenter.default.addObserver(
      forName: UIApplication.willTerminateNotification,
      object: nil,
      queue: nil
    ) { [weak self] notification in
      self?.ep = nil
    }
  }
  
  // MARK: - Deinit
  deinit {
    ep = nil
  }
  
  private func initPlayer() {
    ep = BNBOffscreenEffectPlayer(
      effectWidth: UInt(renderSize.width),
      andHeight: UInt(renderSize.height),
      manualAudio: false
    )
    ep?.enableAudio(false)
  }
}

// MARK: - SDKMaskPostprocessServicing
extension MaskPostprocessingService: SDKMaskPostprocessServicing {
  public func processVideoFrame(_ from: CVPixelBuffer, to: CVPixelBuffer, time: CMTime) {
    renderQueue.sync { [weak self] in
      guard
        let self = self,
        let effectPlayer = self.ep
      else {
        return
      }
      
      var imageFormat = EpImageFormat(
        imageSize: CGSize(width: self.renderSize.width, height: self.renderSize.height),
        orientation: .angles0,
        resultedImageOrientation: .angles180,
        isMirrored: self.isMirrored,
        needAlphaInOutput: self.needAlphaInOutput,
        overrideOutputToBGRA: self.overrideOutputToBGRA,
        outputTexture: self.shouldOutputTexture
      )
      
      autoreleasepool {
        if let pb = effectPlayer.processImage(from, with: &imageFormat) {
          CVPixelBufferLockBaseAddress(pb, .readOnly)
          CVPixelBufferLockBaseAddress(to, .readOnly)
          
          let bytes = CVPixelBufferGetDataSize(from)
          let srcBaseAddress = CVPixelBufferGetBaseAddress(pb)
          let dstBaseAddress = CVPixelBufferGetBaseAddress(to)
          memcpy(dstBaseAddress, srcBaseAddress, bytes)
          
          CVPixelBufferUnlockBaseAddress(pb, .readOnly)
          CVPixelBufferUnlockBaseAddress(to, .readOnly)
        }
      }
    }
  }
  
  public func surfaceCreated(with size: CGSize) {
    ep?.surfaceChanged(UInt(size.width), withHeight: UInt(size.height))
  }
  
  public func setEffectSize(_ size: CGSize) {
    renderSize = size
  }
  
  public func loadEffect(path: String) {
    ep?.loadEffect(path)
    ep?.callJsMethod("hideInteractive", withParam: "")
  }

  public func unloadEffect() {
    ep?.unloadEffect()
  }
}
