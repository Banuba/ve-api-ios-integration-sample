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
import VEPlaybackSDK
import BanubaUtilities

// MARK: - Processing Helpers
extension PlaybackViewController {
  func seetupPlaybackServices() {
    self.effectApplicator = EffectApplicator(
      editor: editor,
      effectConfigHolder: EditorEffectsConfigHolder(token: AppDelegate.licenseToken)
    )
    self.playbackSDK = VEPlayback(videoEditorService: editor)
  }
  
  func setupPlayback(with videoUrls: [URL]) {
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

    // Apply original track rotation for each asset track
    videoEditorAsset.tracksInfo.forEach { assetTrack in
      let rotation = VideoEditorTrackRotationCalculator.getTrackRotation(assetTrack)
      effectApplicator.addTransformEffect(
        atStartTime: assetTrack.timeRangeInGlobal.start,
        end: assetTrack.timeRangeInGlobal.end,
        rotation: rotation,
        isVideoFitsAspect: false
      )
    }
    
    // Set current video asset to video editor service
    editor.setCurrentAsset(videoEditorAsset)
    // Set initial video size
    editor.videoSize = videoSequence.videos.map { $0.videoInfo.resolution }.first!
  }
  
  func applyEffect(_ exportEffect: ExportEffect) {
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
    case .mask:
      guard let name = additionalInfo[ExportEffectAdditionalInfoKey.name] as? String,
            let maskPath = additionalInfo[ExportEffectAdditionalInfoKey.url] as? String else {
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
        start: exportEffect.startTime,
        end: exportEffect.endTime,
        removeSameType: true
      )
    case .music:
      guard let title = additionalInfo[ExportEffectAdditionalInfoKey.name] as? String,
            let musicUrl = additionalInfo[ExportEffectAdditionalInfoKey.url] as? URL else {
        return
      }
      
      let trackTimeRange = CMTimeRange(
        start: exportEffect.startTime,
        duration: exportEffect.startTime + exportEffect.endTime
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

