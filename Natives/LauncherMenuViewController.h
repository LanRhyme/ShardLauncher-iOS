#import <UIKit/UIKit.h>

@interface LauncherMenuCustomItem : NSObject
@property(nonatomic) NSString *title, *imageName;
@property(nonatomic, copy) void (^action)(void);
@property(nonatomic) NSArray<UIViewController *> *vcArray;

// Add public declarations for the class methods
+ (instancetype)vcClass:(Class)class;
+ (instancetype)title:(NSString *)title imageName:(NSString *)imageName action:(id)action;

@end

@interface LauncherMenuViewController : UITableViewController

@property NSString* listPath;
@property(nonatomic) BOOL isInitialVc;

- (void)restoreHighlightedSelection;

@end
