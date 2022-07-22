@import Foundation;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BNBAsyncOperation)
@interface BNBAsyncOperation : NSOperation

- (void)operationDidStart;
- (void)complete NS_REQUIRES_SUPER;
- (void)cancel NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
