#import "ZeroTierBridge.h"
#import "ZeroTierSockets.h"

@interface ZeroTierBridge () <ZTNodeDelegate>

@property (nonatomic, strong) ZTNode *node;

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
    self.node = [[ZTNode alloc] initWithPath:path port:0 delegate:self];
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

#pragma mark - ZTNodeDelegate

- (void)ztnode:(ZTNode *)node event:(ZTEvent)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (event) {
            case ZTEventNodeUp:
                if ([self.delegate respondsToSelector:@selector(zeroTierNodeOnlineWithID:)]) {
                    [self.delegate zeroTierNodeOnlineWithID:self.node.address];
                }
                break;
            case ZTEventNodeDown:
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

- (void)ztnode:(ZTNode *)node joinedNetwork:(uint64_t)networkID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierDidJoinNetwork:)]) {
            [self.delegate zeroTierDidJoinNetwork:networkID];
        }
    });
}

- (void)ztnode:(ZTNode *)node leftNetwork:(uint64_t)networkID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierDidLeaveNetwork:)]) {
            [self.delegate zeroTierDidLeaveNetwork:networkID];
        }
    });
}

- (void)ztnode:(ZTNode *)node assignedAddress:(NSString *)ip forNetwork:(uint64_t)networkID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierDidReceiveIPAddress:forNetworkID:)]) {
            [self.delegate zeroTierDidReceiveIPAddress:ip forNetworkID:networkID];
        }
    });
}

- (void)ztnode:(ZTNode *)node failedToJoinNetwork:(uint64_t)networkID withError:(ZTJoinError)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(zeroTierFailedToJoinNetwork:withError:)]) {
            NSString *errorString = @"Unknown error";
            if (error == ZTJoinErrorNotFound) {
                errorString = @"Network not found";
            } else if (error == ZTJoinErrorAccessDenied) {
                errorString = @"Access denied";
            }
            [self.delegate zeroTierFailedToJoinNetwork:networkID withError:errorString];
        }
    });
}

@end