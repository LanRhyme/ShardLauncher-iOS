#import "ZeroTierBridge.h"
#import <zt/ZeroTier.h>

@interface ZeroTierBridge () <ZeroTierNodeDelegate>

@property (nonatomic, strong) ZeroTierNode *node;

@end

@implementation ZeroTierBridge

+ (instancetype)sharedInstance {
    static ZeroTierBridge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)startNodeWithHomeDirectory:(NSString *)path {
    if (self.node) {
        [self.node stop];
    }
    self.node = [[ZeroTierNode alloc] initWithPath:path port:0 delegate:self];
    [self.node start];
}

- (void)stopNode {
    [self.node stop];
    self.node = nil;
}

- (void)joinNetworkWithID:(uint64_t)networkID {
    [self.node join:networkID];
}

- (void)leaveNetworkWithID:(uint64_t)networkID {
    [self.node leave:networkID];
}

- (uint64_t)nodeID {
    return self.node.address;
}

- (BOOL)isNodeOnline {
    return self.node.online;
}

#pragma mark - ZeroTierNodeDelegate

- (void)zeroTierNode:(ZeroTierNode *)node event:(ZeroTierEvent)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (event) {
            case ZeroTierEventNodeUp:
                if ([self.delegate respondsToSelector:@selector(zeroTierNodeOnlineWithID:)]) {
                    [self.delegate zeroTierNodeOnlineWithID:self.node.address];
                }
                break;
            case ZeroTierEventNodeDown:
                if ([self.delegate respondsToSelector:@selector(zeroTierNodeOffline)]) {
                    [self.delegate zeroTierNodeOffline];
                }
                break;
            default:
                // Other events can be handled here if needed
                break;
        }
    });
}

- (void)zeroTierNode:(ZeroTierNode *)node joinedNetwork:(uint64_t)networkID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierDidJoinNetwork:)]) {
            [self.delegate zeroTierDidJoinNetwork:networkID];
        }
    });
}

- (void)zeroTierNode:(ZeroTierNode *)node leftNetwork:(uint64_t)networkID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierDidLeaveNetwork:)]) {
            [self.delegate zeroTierDidLeaveNetwork:networkID];
        }
    });
}

- (void)zeroTierNode:(ZeroTierNode *)node assignedAddress:(NSString *)ip forNetwork:(uint64_t)networkID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierDidReceiveIPAddress:forNetworkID:)]) {
            [self.delegate zeroTierDidReceiveIPAddress:ip forNetworkID:networkID];
        }
    });
}

- (void)zeroTierNode:(ZeroTierNode *)node failedToJoinNetwork:(uint64_t)networkID withError:(ZeroTierJoinError)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierFailedToJoinNetwork:withError:)]) {
            NSString *errorString = @"Unknown error";
            if (error == ZeroTierJoinErrorNotFound) {
                errorString = @"Network not found";
            } else if (error == ZeroTierJoinErrorAccessDenied) {
                errorString = @"Access denied";
            }
            [self.delegate zeroTierFailedToJoinNetwork:networkID withError:errorString];
        }
    });
}

@end