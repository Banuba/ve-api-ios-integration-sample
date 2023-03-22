
import Foundation
import BanubaSdk
import BanubaEffectPlayer
import BanubaUtilities
import VEEffectsSDK
import VideoEditor

class VideoEditorApiModule {
    
    /// Setups resolution used for playback and export
    let videoResolutionConfiguration = VideoResolutionConfiguration(
        default: .hd1280x720,
        resolutions: [:],
        thumbnailHeights: [:],
        defaultThumbnailHeight: 400.0
    )
    
    let editor: VideoEditorService
    
    init() {
        guard let editor = VideoEditorService(token: AppDelegate.licenseToken) else {
            fatalError("The token is invalid. Please check if token contains all characters.")
        }
        
        self.editor = editor
    }
    
    func initFaceAR() {
        let bundleRoot = Bundle.init(for: BNBEffectPlayer.self).bundlePath
             let dirs = [bundleRoot + "/bnb-resources", Bundle.main.bundlePath + "/effects"]
             BanubaSdkManager.initialize(
                resourcePath: dirs,
                clientTokenString: AppDelegate.licenseToken,
             logLevel: .info
             )
        
        BanubaMaskRenderer.postprocessServicing = MaskPostprocessingService(
            renderSize: videoResolutionConfiguration.current.size
        )
    }
    
}
