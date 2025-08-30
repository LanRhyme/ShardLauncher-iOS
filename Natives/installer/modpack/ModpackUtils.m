#import "ModpackUtils.h"
#import "AFNetworking.h"
#import "UnzipKit.h"
#import "../FabricUtils.h"

@implementation ModpackUtils

+ (void)archive:(UZKArchive *)archive extractDirectory:(NSString *)dir toPath:(NSString *)path error:(NSError **)error {
    // TODO: Not yet implemented
}

+ (NSDictionary *)infoForDependencies:(NSDictionary *)dependency {
    // TODO: Not yet implemented
    return @{};
}

- (void)installModpack:(NSDictionary *)modpack {
    // Implementation likely involves downloading and then calling processDependencies
}

- (void)processDependencies:(NSArray *)dependencies
             minecraftVersion:(NSString *)minecraftVersion
                   completion:(void (^)(NSError * _Nullable))completion {
    // Implementation likely involves downloading files and unzipping them using UnzipKit
}

- (NSDictionary *)processDependency:(NSDictionary *)dependency
                   minecraftVersion:(NSString *)minecraftVersion {
    NSMutableDictionary *info = [NSMutableDictionary new];
    NSString *loader = dependency[@"fabric-loader"] ? @"Fabric" : @"Quilt";

    if ([loader isEqualToString:@"Fabric"]) {
        info[@"json"] = [NSString stringWithFormat:[[FabricUtils endpoints] objectForKey:@"Fabric"][@"json"], minecraftVersion, dependency[@"fabric-loader"]];
    } else {
        info[@"json"] = [NSString stringWithFormat:[[FabricUtils endpoints] objectForKey:@"Quilt"][@"json"], minecraftVersion, dependency[@"quilt-loader"]];
    }
    return info;
}

@end
