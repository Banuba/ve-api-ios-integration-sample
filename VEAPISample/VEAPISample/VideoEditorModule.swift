
import Foundation
import BanubaSdk
import BanubaEffectPlayer
import BanubaUtilities
import VEEffectsSDK

class VideoEditorModule {
    
    /// Setups resolution used for playback and export
    let videoResolutionConfiguration = VideoResolutionConfiguration(
      default: .hd1280x720,
      resolutions: [:],
      thumbnailHeights: [:],
      defaultThumbnailHeight: 400.0
    )
    
    func setupMaskRenderer() {
        BanubaMaskRenderer.postprocessServicing = MaskPostprocessingService(
          renderSize: videoResolutionConfiguration.current.size
        )
    }
 
}
