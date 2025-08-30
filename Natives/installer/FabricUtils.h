#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FabricUtils : NSObject

// This property is publicly readonly and immutable.
@property (nonatomic, strong, readonly) NSArray<NSDictionary *> *versions;

// Class method to access endpoints, visible to other modules.
+ (NSDictionary *)endpoints;

- (void)fetchVersionsWithCallback:(void (^)(NSError * _Nullable))callback;
- (void)installVersion:(NSInteger)index withCallback:(void (^)(NSString * _Nullable, NSError * _Nullable))callback;

@end

NS_ASSUME_NONNULL_END
