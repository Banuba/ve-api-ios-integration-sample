//
//  EffectsManager.swift
//  VEAPISample
//
//  Created by Andrey Sak on 6.03.23.
//

import VEEffectsSDK
import VideoEditor
import BanubaUtilities

class EffectsManager {
    
    let editor: VideoEditorService
    private let effectApplicator: EffectApplicator
    
    init(editor: VideoEditorService) {
        self.editor = editor
        self.effectApplicator = EffectApplicator(
            editor: editor,
            effectConfigHolder: EditorEffectsConfigHolder(token: AppDelegate.licenseToken)
        )
    }
    
    /// Applying transformation and rotation effect
    func applyTransformEffect(start: CMTime, end: CMTime, rotation: AssetRotation) {
        effectApplicator.addTransformEffect(
            atStartTime: start,
            end: end,
            rotation: rotation,
            isVideoFitsAspect: false
        )
    }
    
    /// Applying color effect with specified url name and time info
    func applyColorEffect(_ effect: Effect) {
        let additionalInfo = effect.additionalInfo
        guard let lutUrl = additionalInfo[Effect.AdditionalInfoKey.url] as? URL,
              let name = additionalInfo[Effect.AdditionalInfoKey.name] as? String else {
            fatalError("Missed Color effect parameters!")
        }
        effectApplicator.applyColorEffect(
            name: name,
            lutUrl: lutUrl,
            startTime: effect.timeRange.start,
            endTime: effect.timeRange.end,
            removeSameType: false,
            effectId: effect.id
        )
    }
    
    /// Undo last applied color effect
    func undoColorEffect() {
        editor.undoLast(type: .color)
    }
    
    /// Applying visual effect with specified type and time info
    func applyVisualEffect(_ visualEffect: Effect) {
        guard let visualEffectType = visualEffect.additionalInfo[Effect.AdditionalInfoKey.name] as? VisualEffectApplicatorType else {
            fatalError("Missed Visual effect parameters!")
        }
        
        effectApplicator.applyVisualEffectApplicatorType(
            visualEffectType,
            startTime: visualEffect.timeRange.start,
            endTime: visualEffect.timeRange.end,
            removeSameType: false,
            effectId: visualEffect.id
        )
    }
    
    /// Undo last applied visual effect
    func undoVisualEffect() {
        editor.undoLast(type: .visual)
    }
    
    /// Applying speed effect with specified type and time info
    func applySpeedEffect(_ speedEffect: Effect) {
        guard let speedEffectType = speedEffect.additionalInfo[Effect.AdditionalInfoKey.name] as? SpeedEffectType else {
            return
        }
        
        effectApplicator.applySpeedEffectType(
            speedEffectType,
            startTime: speedEffect.timeRange.start,
            endTime: speedEffect.timeRange.end,
            removeSameType: false,
            effectId: speedEffect.id
        )
    }
    
    /// Undo effect with specific id
    func undoEffect(withId id: UInt?) {
        guard let id else { return }
        editor.undo(withId: id)
    }
    
    /// Applying overlay effect with specified type and overlay settings
    func applyOverlayEffect(_ overlayEffect: Effect) {
        let additionalInfo = overlayEffect.additionalInfo
        guard let type = additionalInfo[Effect.AdditionalInfoKey.name] as? OverlayEffectApplicatorType,
              let effectInfo = additionalInfo[Effect.AdditionalInfoKey.effectSettings] as? VideoEditorEffectInfo else {
            return
        }
        
        effectApplicator.applyOverlayEffectType(
            type,
            effectInfo: effectInfo
        )
    }
    
    /// Applying mask with specified name, url and time info
    func applyMaskEffect(_ maskEffect: Effect) {
        let additionalInfo = maskEffect.additionalInfo
        
        guard let name = additionalInfo[Effect.AdditionalInfoKey.name] as? String,
              let maskPath = additionalInfo[Effect.AdditionalInfoKey.url] as? String else {
            return
        }
        
        let effectModel = VideoEditorFilterModel(
            name: name,
            type: .mask,
            renderer: BanubaMaskDrawer.self,
            path: maskPath,
            id: maskEffect.id,
            tokenId: "\(maskEffect.id)",
            rendererInstance: nil,
            preview: nil,
            additionalParameters: nil
        )
        
        // Setup Banuba Mask Renderer
        // This operation can be time consuming
        BanubaMaskRenderer.loadEffectPath(maskPath)
        
        editor.applyFilter(
            effectModel: effectModel,
            start: maskEffect.timeRange.start,
            end: maskEffect.timeRange.end,
            removeSameType: true
        )
    }
    
    func undoMaskEffect() {
        editor.undoAll(type: .mask)
    }
    
    /// Appling music effect with specified name, url, and time info
    func applyMusicEffect(_ musicEffect: Effect) {
        let additionalInfo = musicEffect.additionalInfo
        guard let title = additionalInfo[Effect.AdditionalInfoKey.name] as? String,
              let musicUrl = additionalInfo[Effect.AdditionalInfoKey.url] as? URL else {
            return
        }
        
        let trackTimeRange = CMTimeRange(
            start: musicEffect.timeRange.start,
            duration: musicEffect.timeRange.duration
        )
        
        // Track time range
        let timeRange = MediaTrackTimeRange(
            startTime: .zero,
            playingTimeRange: trackTimeRange
        )
        
        // Track instance
        let track = MediaTrack(
            uuid: UUID(),
            id: CMPersistentTrackID(musicEffect.id),
            url: musicUrl,
            timeRange: timeRange,
            isEditable: true,
            title: title
        )
        editor.videoAsset?.addMusicTrack(track)
    }
    
    func undoMusicEffect(id: CMPersistentTrackID, url: URL) {
        editor.videoAsset?.removeMusic(trackId: id, url: url)
    }
    
    func undoAll(type: VideoEditor.EditorEffectType) {
        editor.undoAll(type: type)
    }
}
