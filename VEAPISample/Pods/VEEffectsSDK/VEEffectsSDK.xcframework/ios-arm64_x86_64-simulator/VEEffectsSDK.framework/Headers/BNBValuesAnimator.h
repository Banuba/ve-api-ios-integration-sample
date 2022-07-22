#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    size_t durationInMilliseconds;
    size_t initialDelayInMilliseconds;
    size_t delayInMilliseconds;
    size_t delayRandomizerInMilliseconds;
    NSInteger repeatsCount;
    BOOL reverseOnRepeat;
} BNBValuesAnimatorParameters;

@interface BNBValuesAnimator : NSObject

+ (BNBValuesAnimatorParameters)parameters:(size_t)durationInMilliseconds
                      delayInMilliseconds:(size_t)delayInMilliseconds
            delayRandomizerInMilliseconds:(size_t)delayRandomizerInMilliseconds
                             repeatsCount:(NSInteger)repeatsCount
                          reverseOnRepeat:(BOOL)reverseOnRepeat;

+ (float)animated_float_quad_ease_out:(CMTime)time
                                start:(float)start
                               finish:(float)finish
                  animationParameters:(BNBValuesAnimatorParameters)animationParameters;

+ (float)animated_float_expo_ease_in:(CMTime)time
                               start:(float)start
                              finish:(float)finish
                 animationParameters:(BNBValuesAnimatorParameters)animationParameters;

+ (float)animated_float_expo_ease_in_out:(CMTime)time
                                   start:(float)start
                                  finish:(float)finish
                     animationParameters:(BNBValuesAnimatorParameters)animationParameters;

@end

NS_ASSUME_NONNULL_END
