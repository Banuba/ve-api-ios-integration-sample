// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from types.djinni

#import "BNBTransformedMaskByte.h"
#import <Foundation/Foundation.h>

@interface BNBEyesPupilMask : NSObject
- (nonnull instancetype)initWithLeft:(nonnull BNBTransformedMaskByte *)left
                               right:(nonnull BNBTransformedMaskByte *)right;
+ (nonnull instancetype)eyesPupilMaskWithLeft:(nonnull BNBTransformedMaskByte *)left
                                        right:(nonnull BNBTransformedMaskByte *)right;

@property (nonatomic, readonly, nonnull) BNBTransformedMaskByte * left;

@property (nonatomic, readonly, nonnull) BNBTransformedMaskByte * right;

@end
