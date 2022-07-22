//
//  OutputSettings.h
//  OutputSettings
//
//  Created by Andrei Sak on 9.09.21.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface OutputSettings : NSObject

@property(nonatomic) UIDeviceOrientation deviceOrientation;
@property(nonatomic) BOOL isMirrored;
@property(nonatomic) BOOL applyWatermark;

@property(nonatomic, readonly) BOOL shouldApplyVerticalFlip;
@property(nonatomic, readonly) BOOL shouldApplyHorizontalFlip;
@property(nonatomic, readonly) CGAffineTransform resultVideoTransform;
@property(nonatomic, readonly) UIImageOrientation resultImageOrientation;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOrientation:(UIDeviceOrientation)orientation
                         isMirrored:(BOOL)isMirrored
                     applyWatermark:(BOOL)applyWatermark NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
