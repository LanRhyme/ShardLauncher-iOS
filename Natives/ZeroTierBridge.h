#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declaration to avoid importing the whole framework in the public header
@class ZeroTierNode;

@protocol ZeroTierBridgeDelegate <NSObject>

- (void)zeroTierNodeOnlineWithID:(uint64_t)nodeID;
- (void)zeroTierNodeOffline;
- (void)zeroTierDidJoinNetwork:(uint64_t)networkID;
- (void)zeroTierDidLeaveNetwork:(uint64_t)networkID;
- (void)zeroTierFailedToJoinNetwork:(uint64_t)networkID withError:(NSString *)error;
- (void)zeroTierDidReceiveIPAddress:(NSString *)ipAddress forNetworkID:(uint64_t)networkID;

@end

@interface ZeroTierBridge : NSObject

@property (nonatomic, weak) id<ZeroTierBridgeDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)startNodeWithHomeDirectory:(NSString *)path;
- (void)stopNode;

- (void)joinNetworkWithID:(uint64_t)networkID;
- (void)leaveNetworkWithID:(uint64_t)networkID;

- (uint64_t)nodeID;
- (BOOL)isNodeOnline;

@end

NS_ASSUME_NONNULL_END
