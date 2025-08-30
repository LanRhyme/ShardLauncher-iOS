#import "MainContentViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherNavigationController.h"

@interface MainContentViewController ()

@end

@implementation MainContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    // The menu is now handled by the UISplitViewController.
    // This view controller is just for the main content.

    // The initial content is LauncherNewsViewController, wrapped in a navigation controller.
    // This is only created if no contentViewController has been set (e.g. from storyboard or state restoration).
    if (!self.contentViewController) {
        self.contentViewController = [[LauncherNavigationController alloc] initWithRootViewController:[[LauncherNewsViewController alloc] init]];
        self.contentViewController.navigationBarHidden = YES;

        [self addChildViewController:self.contentViewController];
        [self.view addSubview:self.contentViewController.view];
        self.contentViewController.view.frame = self.view.bounds;
        self.contentViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentViewController didMoveToParentViewController:self];
    }
}

- (void)navigateToViewController:(UIViewController *)viewController {
    // This implementation is preserved from the original file to keep the custom transition.
    
    // Add the new view controller
    [self.contentViewController addChildViewController:viewController];
    viewController.view.frame = self.contentViewController.view.bounds;
    [self.contentViewController.view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self.contentViewController];

    // Fade out the old one, fade in the new one
    UIViewController *oldViewController = self.contentViewController.viewControllers.firstObject;
    viewController.view.alpha = 0;

    [UIView animateWithDuration:0.3 animations:^{
        viewController.view.alpha = 1;
        oldViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [oldViewController.view removeFromSuperview];
        [oldViewController removeFromParentViewController];
        [self.contentViewController setViewControllers:@[viewController] animated:NO];
    }];
}

@end
