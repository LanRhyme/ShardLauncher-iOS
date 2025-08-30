#import "ZeroTierBridge.h"
#import "ZeroTierSockets.h"

@interface ZeroTierBridge ()
- (void)handleEvent:(zts_event_msg_t *)msg;
@end

static void event_cb(void *msg_ptr) {
    zts_event_msg_t *msg = (zts_event_msg_t *)msg_ptr;
    [[ZeroTierBridge sharedInstance] handleEvent:msg];
}

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
    zts_init_set_event_handler(&event_cb);
    zts_init_from_storage([path UTF8String]);
    zts_node_start();
}

- (void)stopNode {
    zts_node_stop();
}

- (void)joinNetworkWithID:(uint64_t)networkID {
    zts_net_join(networkID);
}

- (void)leaveNetworkWithID:(uint64_t)networkID {
    zts_net_leave(networkID);
}

- (uint64_t)nodeID {
    return zts_node_get_id();
}

- (BOOL)isNodeOnline {
    return zts_node_is_online();
}

- (void)handleEvent:(zts_event_msg_t *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (msg->event_code) {
            case ZTS_EVENT_NODE_UP:
                if ([self.delegate respondsToSelector:@selector(zeroTierNodeOnlineWithID:)]) {
                    [self.delegate zeroTierNodeOnlineWithID:zts_node_get_id()];
                }
                break;
            case ZTS_EVENT_NODE_DOWN:
                if ([self.delegate respondsToSelector:@selector(zeroTierNodeOffline)]) {
                    [self.delegate zeroTierNodeOffline];
                }
                break;
            case ZTS_EVENT_NETWORK_OK:
                if ([self.delegate respondsToSelector:@selector(zeroTierDidJoinNetwork:)]) {
                    [self.delegate zeroTierDidJoinNetwork:msg->network->net_id];
                }
                break;
            case ZTS_EVENT_NETWORK_ACCESS_DENIED:
            case ZTS_EVENT_NETWORK_NOT_FOUND:
                if ([self.delegate respondsToSelector:@selector(zeroTierFailedToJoinNetwork:withError:)]) {
                    uint64_t networkId = (msg->event_code == ZTS_EVENT_NETWORK_NOT_FOUND) ? msg->netif->net_id : msg->network->net_id;
                    NSString *errorString = (msg->event_code == ZTS_EVENT_NETWORK_NOT_FOUND) ? @"Network not found" : @"Access denied";
                    [self.delegate zeroTierFailedToJoinNetwork:networkId withError:errorString];
                }
                break;
            case ZTS_EVENT_ADDR_ADDED_IP4:
            case ZTS_EVENT_ADDR_ADDED_IP6: {
                if ([self.delegate respondsToSelector:@selector(zeroTierDidReceiveIPAddress:forNetworkID:)]) {
                    char ip_str[ZTS_IP_MAX_STR_LEN];
                    zts_util_ntop((struct zts_sockaddr *)&msg->addr->addr, sizeof(msg->addr->addr), ip_str, ZTS_IP_MAX_STR_LEN, NULL);
                    NSString *ip = [NSString stringWithUTF8String:ip_str];
                    [self.delegate zeroTierDidReceiveIPAddress:ip forNetworkID:msg->addr->net_id];
                }
                break;
            }
        }
    });
}

@end