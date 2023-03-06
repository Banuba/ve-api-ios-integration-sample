//
//  EffectsApplyer.swift
//  VEAPISample
//
//  Created by Andrey Sak on 6.03.23.
//

import VEEffectsSDK
import VideoEditor
import BanubaUtilities

class EffectsApplyer {
  
  let editor: VideoEditorService
  private let effectApplicator: EffectApplicator
  
  init(editor: VideoEditorService) {
    self.editor = editor
    self.effectApplicator = EffectApplicator(
      editor: editor,
      effectConfigHolder: EditorEffectsConfigHolder(token: AppDelegate.licenseToken)
    )
  }
  
  func applyTransformEffect(start: CMTime, end: CMTime, rotation: AssetRotation) {
    effectApplicator.addTransformEffect(
      atStartTime: start,
      end: end,
      rotation: rotation,
      isVideoFitsAspect: false
    )
  }
  
  func applyEffect(_ exportEffect: Effect) {
    let additionalInfo = exportEffect.additionalInfo
    switch exportEffect.type {
    case .color:
      guard let lutUrl = additionalInfo[Effect.AdditionalInfoKey.url] as? URL,
            let name = additionalInfo[Effect.AdditionalInfoKey.name] as? String else {
        return
      }
      effectApplicator.applyColorEffect(
        name: name,
        lutUrl: lutUrl,
        startTime: exportEffect.timeRange.start,
        endTime: exportEffect.timeRange.end,
        removeSameType: false,
        effectId: exportEffect.id
      )
    case .visual:
      guard let visualEffectType = additionalInfo[Effect.AdditionalInfoKey.name] as? VisualEffectApplicatorType else {
        return
      }
      
      effectApplicator.applyVisualEffectApplicatorType(
        visualEffectType,
        startTime: exportEffect.timeRange.start,
        endTime: exportEffect.timeRange.end,
        removeSameType: false,
        effectId: exportEffect.id
      )
    case .speed:
      guard let speedEffectType = additionalInfo[Effect.AdditionalInfoKey.name] as? SpeedEffectType else {
        return
      }
      
      effectApplicator.applySpeedEffectType(
        speedEffectType,
        startTime: exportEffect.timeRange.start,
        endTime: exportEffect.timeRange.end,
        removeSameType: false,
        effectId: exportEffect.id
      )
    case .overlay:
      guard let type = additionalInfo[Effect.AdditionalInfoKey.name] as? OverlayEffectApplicatorType,
            let effectInfo = additionalInfo[Effect.AdditionalInfoKey.effectSettings] as? VideoEditorEffectInfo else {
        return
      }
      
      effectApplicator.applyOverlayEffectType(
        type,
        effectInfo: effectInfo
      )
    case .mask:
      guard let name = additionalInfo[Effect.AdditionalInfoKey.name] as? String,
            let maskPath = additionalInfo[Effect.AdditionalInfoKey.url] as? String else {
        return
      }
      
      let effectModel = VideoEditorFilterModel(
        name: name,
        type: .mask,
        renderer: BanubaMaskDrawer.self,
        path: maskPath,
        id: exportEffect.id,
        tokenId: "\(exportEffect.id)",
        rendererInstance: nil,
        preview: nil,
        additionalParameters: nil
      )
      
      // Setup Banuba Mask Renderer
      // This operation can be time consuming
      BanubaMaskRenderer.loadEffectPath(maskPath)
      
      editor.applyFilter(
        effectModel: effectModel,
        start: exportEffect.timeRange.start,
        end: exportEffect.timeRange.end,
        removeSameType: true
      )
    case .music:
      guard let title = additionalInfo[Effect.AdditionalInfoKey.name] as? String,
            let musicUrl = additionalInfo[Effect.AdditionalInfoKey.url] as? URL else {
        return
      }
      
      let trackTimeRange = CMTimeRange(
        start: exportEffect.timeRange.start,
        duration: exportEffect.timeRange.duration
      )
      
      // Track time range
      let timeRange = MediaTrackTimeRange(
        startTime: .zero,
        playingTimeRange: trackTimeRange
      )
      
      // Track instance
      let track = MediaTrack(
        uuid: UUID(),
        id: CMPersistentTrackID(exportEffect.id),
        url: musicUrl,
        timeRange: timeRange,
        isEditable: true,
        title: title
      )
      editor.videoAsset?.addMusicTrack(track)
    }
  }
}
