//
//  Processing.swift
//  VEAPISample
//
//  Created by Banuba on 29.12.22.
//

import Foundation

// Banuba Modules
import VideoEditor
import VEEffectsSDK

// MARK: - Processing Helpers
extension PlaybackViewController {
  func processVideo(videoUrls: [URL]) {
    
    // Get sequence folder url
    let sequenceName = UUID().uuidString
    let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(sequenceName)
    
    // Add video to the sequence
    let videoSequence = VideoSequence(folderURL: folderURL)
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
    
    // Set cuurent video asset to video editor service
    CoreAPI.shared.coreAPI.setCurrentAsset(videoEditorAsset)

    // Apply original track rotation for each asset track
    videoEditorAsset.tracksInfo.forEach { assetTrack in
      let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(assetTrack)
      EffectsAPI.shared.effectApplicator.addTransformEffect(
        atStartTime: assetTrack.timeRangeInGlobal.start,
        end: assetTrack.timeRangeInGlobal.end,
        rotation: rotation,
        isVideoFitsAspect: false
      )
    }
    
    let effectApplicator = EffectsAPI.shared.effectApplicator

    let exportEffectsProvider = ExportEffectProvider(totalVideoDuration: videoEditorAsset.composition.duration)
    exportEffectsProvider.provideExportEffects().forEach { exportEffect in
      let additionalInfo = exportEffect.additionalInfo
      switch exportEffect.type {
      case .color:
        guard let lutUrl = additionalInfo[ExportEffectAdditionalInfoKey.url] as? URL,
              let name = additionalInfo[ExportEffectAdditionalInfoKey.name] as? String else {
          return
        }
        effectApplicator.applyColorEffect(
          name: name,
          lutUrl: lutUrl,
          startTime: exportEffect.startTime,
          endTime: exportEffect.endTime,
          removeSameType: false,
          effectId: exportEffect.id
        )
      case .visual:
        guard let visualEffectType = additionalInfo[ExportEffectAdditionalInfoKey.name] as? VisualEffectApplicatorType else {
          return
        }
        
        effectApplicator.applyVisualEffectApplicatorType(
          visualEffectType,
          startTime: exportEffect.startTime,
          endTime: exportEffect.endTime,
          removeSameType: false,
          effectId: exportEffect.id
        )
      case .speed:
        guard let speedEffectType = additionalInfo[ExportEffectAdditionalInfoKey.name] as? SpeedEffectType else {
          return
        }
        
        effectApplicator.applySpeedEffectType(
          speedEffectType,
          startTime: exportEffect.startTime,
          endTime: exportEffect.endTime,
          removeSameType: false,
          effectId: exportEffect.id
        )
      case .overlay:
        guard let type = additionalInfo[ExportEffectAdditionalInfoKey.name] as? OverlayEffectApplicatorType,
              let effectInfo = additionalInfo[ExportEffectAdditionalInfoKey.effectInfo] as? VideoEditorEffectInfo else {
          return
        }
        
        effectApplicator.applyOverlayEffectType(
          type,
          effectInfo: effectInfo
        )
      }
    }
  }
}

