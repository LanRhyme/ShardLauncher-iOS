#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LauncherMenuViewController, LauncherNavigationController;

@interface MainContentViewController : UIViewController

@property (nonatomic, strong) LauncherMenuViewController *menuViewController;
@property (nonatomic, strong) LauncherNavigationController *contentViewController;
@property (nonatomic, strong) UIBarButtonItem *accountButton;

// Make this property public so the menu can access it to update its layout
@property (nonatomic, assign, readonly) BOOL isSidebarExpanded;

- (void)navigateToViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
