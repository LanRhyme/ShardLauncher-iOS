#import "FabricUtils.h"
#import "AFNetworking.h"
#import "PLProfiles.h"
#import "utils.h"

// Private interface for internal use
@interface FabricUtils ()
// Redeclare 'versions' as readwrite for internal use.
@property (nonatomic, strong, readwrite) NSArray<NSDictionary *> *versions;
@end

@implementation FabricUtils

+ (NSDictionary *)endpoints {
    return @{
        @"Fabric": @{
            @"game": @"https://meta.fabricmc.net/v2/versions/game",
            @"loader": @"https://meta.fabricmc.net/v2/versions/loader",
            @"icon": @"https://avatars.githubusercontent.com/u/21025855?s=64",
            @"json": @"https://meta.fabricmc.net/v2/versions/loader/%@/%@/profile/json"
        },
        @"Quilt": @{
            @"game": @"https://meta.quiltmc.org/v3/versions/game",
            @"loader": @"https://meta.quiltmc.org/v3/versions/loader",
            @"icon": @"https://raw.githubusercontent.com/QuiltMC/art/master/brand/64png/quilt_logo_transparent.png",
            @"json": @"https://meta.quiltmc.org/v3/versions/loader/%@/%@/profile/json"
        }
    };
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize with an empty array.
        self.versions = @[];
    }
    return self;
}

- (void)fetchVersionsWithCallback:(void (^)(NSError * _Nullable))callback {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *loaderUrl = [FabricUtils endpoints][@"Fabric"][@"loader"];
    
    [manager GET:loaderUrl parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSArray class]]) {
            NSMutableArray *mutableVersions = [NSMutableArray array];
            for (NSDictionary *loaderVersion in responseObject) {
                if (loaderVersion[@"game_version"] && loaderVersion[@"version"]) {
                    [mutableVersions addObject:loaderVersion];
                }
            }
            [mutableVersions sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"game_version" ascending:NO selector:@selector(compare:)]]];
            self.versions = [mutableVersions copy]; // Assign an immutable copy
        }
        callback(nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        callback(error);
    }];
}

- (void)installVersion:(NSInteger)index withCallback:(void (^)(NSString * _Nullable, NSError * _Nullable))callback {
    if (index >= self.versions.count) {
        callback(nil, [NSError errorWithDomain:@"FabricUtils" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid version index"}]);
        return;
    }
    
    NSDictionary *versionInfo = self.versions[index];
    NSString *gameVersion = versionInfo[@"game_version"];
    NSString *loaderVersion = versionInfo[@"version"];
    
    NSString *profileUrlString = [NSString stringWithFormat:[FabricUtils endpoints][@"Fabric"][@"json"], gameVersion, loaderVersion];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];

    [manager GET:profileUrlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            callback(nil, [NSError errorWithDomain:@"FabricUtils" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid profile JSON"}]);
            return;
        }
        
        NSMutableDictionary *profileJson = [responseObject mutableCopy];
        NSString *versionId = profileJson[@"id"];
        
        NSString *versionDir = [NSString stringWithFormat:@"%s/versions/%@", getenv("POJAV_HOME"), versionId];
        [[NSFileManager defaultManager] createDirectoryAtPath:versionDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *jsonPath = [versionDir stringByAppendingPathComponent:[versionId stringByAppendingString:@".json"]];
        
        saveJSONToFile(profileJson, jsonPath);
        
        NSString *profileName = [NSString stringWithFormat:@"Fabric %@", gameVersion];
        NSMutableDictionary *newProfile = @{
            @"name": profileName,
            @"lastVersionId": versionId,
            @"type": @"custom",
            @"icon": [FabricUtils endpoints][@"Fabric"][@"icon"]
        }.mutableCopy;
        
        // Use the correct method to add a profile
        [PLProfiles.current.profiles setObject:newProfile forKey:profileName];
        [PLProfiles.current save];
        
        callback(gameVersion, nil);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        callback(nil, error);
    }];
}

@end
