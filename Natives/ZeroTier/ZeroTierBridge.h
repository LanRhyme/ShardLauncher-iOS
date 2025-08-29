#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZeroTierBridgeDelegate <NSObject>

- (void)zeroTierStatusDidChange:(NSString *)status;
- (void)zeroTierDidJoinNetwork:(NSString *)networkID withIPAddress:(NSString *)ipAddress;
- (void)zeroTierDidLeaveNetwork:(NSString *)networkID;
- (void)zeroTierDidFailWithError:(NSString *)error;

@end

@interface ZeroTierBridge : NSObject

@property (nonatomic, weak) id<ZeroTierBridgeDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)startNode;
- (void)stopNode;

- (void)createAndJoinPrivateNetwork;
- (void)joinNetworkWithID:(NSString *)networkID;
- (void)leaveNetworkWithID:(NSString *)networkID;

- (NSString *)nodeID;

@end

NS_ASSUME_NONNULL_END
