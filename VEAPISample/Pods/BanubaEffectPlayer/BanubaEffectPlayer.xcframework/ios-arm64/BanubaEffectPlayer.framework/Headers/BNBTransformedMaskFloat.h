// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from types.djinni

#import "BNBTransformedMask.h"
#import <Foundation/Foundation.h>

@interface BNBTransformedMaskFloat : NSObject
- (nonnull instancetype)initWithMeta:(nonnull BNBTransformedMask *)meta
                                mask:(nonnull NSArray<NSNumber *> *)mask;
+ (nonnull instancetype)transformedMaskFloatWithMeta:(nonnull BNBTransformedMask *)meta
                                                mask:(nonnull NSArray<NSNumber *> *)mask;

@property (nonatomic, readonly, nonnull) BNBTransformedMask * meta;

@property (nonatomic, readonly, nonnull) NSArray<NSNumber *> * mask;

@end