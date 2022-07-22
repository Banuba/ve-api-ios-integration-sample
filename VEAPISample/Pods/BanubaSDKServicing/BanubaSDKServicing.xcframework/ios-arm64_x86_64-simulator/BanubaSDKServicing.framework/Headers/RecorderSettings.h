//
//  RecorderSettings.h
//  RecorderSettings
//
//  Created by Andrei Sak on 10.09.21.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface RecorderSettings : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithVideoDataOutput:(AVCaptureVideoDataOutput* _Nullable)videoDataOutput
                            captureSize:(CGSize)captureSize
                 useHEVCCodecIfPossible:(BOOL)useHEVCCodecIfPossible;

@property (readonly, strong, nonatomic) NSDictionary* videoSettings;
@property (readonly, assign, nonatomic) CGSize captureSize;

@end

NS_ASSUME_NONNULL_END
