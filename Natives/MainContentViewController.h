#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LauncherMenuViewController, LauncherNavigationController;

@interface MainContentViewController : UIViewController

@property (nonatomic, strong) LauncherMenuViewController *menuViewController;
@property (nonatomic, strong) LauncherNavigationController *contentViewController;

- (void)navigateToViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
