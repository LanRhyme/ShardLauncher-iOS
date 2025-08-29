#import "ZeroTierBridge.h"
#import "One.h" // This is the main header from the ZeroTier SDK

#define ZT_SERVICE_PORT 9993

@interface ZeroTierBridge () {
    zts_node_t *_node;
    dispatch_queue_t _zt_queue;
}
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _zt_queue = dispatch_queue_create("com.shardlauncher.zerotier.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)startNode {
    dispatch_async(_zt_queue, ^{
        NSString *homePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"zerotier-one"];
        if (![NSFileManager.defaultManager fileExistsAtPath:homePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:homePath withIntermediateDirectories:YES attributes:nil error:nil];
        }

        _node = zts_node_new(homePath.UTF8String, NULL, ZT_SERVICE_PORT);
        if (!_node) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(zeroTierDidFailWithError:)]) {
                    [self.delegate zeroTierDidFailWithError:@"Failed to initialize ZeroTier node."];
                }
            });
            return;
        }

        while (!zts_node_is_online(_node)) {
            [NSThread sleepForTimeInterval:0.1];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(zeroTierStatusDidChange:)]) {
                [self.delegate zeroTierStatusDidChange:@"Online"];
            }
        });
    });
}

- (void)stopNode {
    dispatch_async(_zt_queue, ^{
        if (_node) {
            zts_node_free(_node);
            _node = NULL;
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(zeroTierStatusDidChange:)]) {
                    [self.delegate zeroTierStatusDidChange:@"Offline"];
                }
            });
        }
    });
}

- (NSString *)nodeID {
    if (_node) {
        return [NSString stringWithFormat:@"%llx", zts_node_get_id(_node)];
    }
    return @"Offline";
}

- (void)createAndJoinPrivateNetwork {
    uint64_t network_id_val = 0;
    arc4random_buf(&network_id_val, sizeof(network_id_val));
    // ZeroTier network IDs are 64 bits, but the upper 16 are reserved for flags and special networks.
    // We will use a 48-bit random ID, which is what ZeroTier Central does.
    network_id_val &= 0x0000FFFFFFFFFFFFull;

    NSString *networkID = [NSString stringWithFormat:@"%012llx", network_id_val];
    [self joinNetworkWithID:networkID];
}

- (void)joinNetworkWithID:(NSString *)networkID {
    dispatch_async(_zt_queue, ^{
        if (!_node) return;
        
        uint64_t nwid = 0;
        NSScanner *scanner = [NSScanner scannerWithString:networkID];
        [scanner scanHexLongLong:&nwid];
        
        zts_node_join(_node, nwid);
        
        // Wait for join confirmation and IP address
        int attempts = 0;
        while (attempts < 100) { // Wait up to 10 seconds
            zts_netinfo_t netinfo;
            if (zts_node_get_network_info(_node, nwid, &netinfo) == 0) {
                 for (int i = 0; i < netinfo.ip_count; ++i) {
                    char ip_str[40];
                    zts_ip_to_string(netinfo.ips[i], ip_str, sizeof(ip_str));
                    NSString *ipAddress = [NSString stringWithUTF8String:ip_str];
                    
                    // We only care about IPv4 for Minecraft LAN games
                    if ([ipAddress containsString:@"."]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([self.delegate respondsToSelector:@selector(zeroTierDidJoinNetwork:withIPAddress:)]) {
                                [self.delegate zeroTierDidJoinNetwork:networkID withIPAddress:ipAddress];
                            }
                        });
                        return; // Success
                    }
                }
            }
            [NSThread sleepForTimeInterval:0.1];
            attempts++;
        }
        
        // If we reach here, we failed to get an IP
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(zeroTierDidFailWithError:)]) {
                [self.delegate zeroTierDidFailWithError:[NSString stringWithFormat:@"Failed to join network %@. Timed out.", networkID]];
            }
        });
    });
}

- (void)leaveNetworkWithID:(NSString *)networkID {
    dispatch_async(_zt_queue, ^{
        if (!_node) return;
        
        uint64_t nwid = 0;
        NSScanner *scanner = [NSScanner scannerWithString:networkID];
        [scanner scanHexLongLong:&nwid];
        
        zts_node_leave(_node, nwid);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(zeroTierDidLeaveNetwork:)]) {
                [self.delegate zeroTierDidLeaveNetwork:networkID];
            }
        });
    });
}

@end
