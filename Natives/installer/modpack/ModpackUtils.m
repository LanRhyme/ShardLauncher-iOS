#import "ModpackUtils.h"
#import "AFNetworking.h"
#import "SSZipArchive.h"
#import "../FabricUtils.h"

@implementation ModpackUtils

- (void)installModpack:(NSDictionary *)modpack {
    // ... (code unchanged)
}

- (void)processDependencies:(NSArray *)dependencies
             minecraftVersion:(NSString *)minecraftVersion
                   completion:(void (^)(NSError * _Nullable))completion {
    // ... (code unchanged)
}

- (NSDictionary *)processDependency:(NSDictionary *)dependency
                   minecraftVersion:(NSString *)minecraftVersion {
    NSMutableDictionary *info = [NSMutableDictionary new];
    NSString *loader = dependency[@"fabric-loader"] ? @"Fabric" : @"Quilt";

    if ([loader isEqualToString:@"Fabric"]) {
        info[@"json"] = [NSString stringWithFormat:[FabricUtils endpoints][@"Fabric"][@"json"], minecraftVersion, dependency[@"fabric-loader"]];
    } else {
        info[@"json"] = [NSString stringWithFormat:[FabricUtils endpoints][@"Quilt"][@"json"], minecraftVersion, dependency[@"quilt-loader"]];
    }
    return info;
}

// ... (rest of the file is unchanged)

@end
