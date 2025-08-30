#import "MainContentViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherNavigationController.h"
#import "AccountListViewController.h"

@interface MainContentViewController ()

@property (nonatomic, strong) NSLayoutConstraint *sidebarWidthConstraint;
@property (nonatomic, assign, readwrite) BOOL isSidebarExpanded;

@end

@implementation MainContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.isSidebarExpanded = NO;

    // 1. Instantiate Menu and Content View Controllers
    self.menuViewController = [[LauncherMenuViewController alloc] init];
    
    // The initial content is LauncherNewsViewController, wrapped in a navigation controller
    self.contentViewController = [[LauncherNavigationController alloc] initWithRootViewController:[[LauncherNewsViewController alloc] init]];
    self.contentViewController.navigationBarHidden = YES; // The navigation bar is no longer needed here

    // 2. Add as Child View Controllers
    [self addChildViewController:self.menuViewController];
    [self.view addSubview:self.menuViewController.view];
    [self.menuViewController didMoveToParentViewController:self];

    [self addChildViewController:self.contentViewController];
    [self.view addSubview:self.contentViewController.view];
    [self.contentViewController didMoveToParentViewController:self];

    // 3. Setup Auto Layout
    self.menuViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.sidebarWidthConstraint = [self.menuViewController.view.widthAnchor constraintEqualToConstant:70]; // Initial collapsed width

    [NSLayoutConstraint activateConstraints:@[
        // Menu View (Sidebar)
        [self.menuViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.menuViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.menuViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        self.sidebarWidthConstraint,

        // Content View
        [self.contentViewController.view.leadingAnchor constraintEqualToAnchor:self.menuViewController.view.trailingAnchor],
        [self.contentViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.contentViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    
    // 4. Add expand/collapse button to the menu
    UIBarButtonItem *expandButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"sidebar.leading"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleSidebar)];
    self.menuViewController.navigationItem.leftBarButtonItem = expandButton;
    
    // 5. Add account button
    self.accountButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"person.crop.circle"] style:UIBarButtonItemStylePlain target:self action:@selector(openAccountManager)];
    self.menuViewController.navigationItem.rightBarButtonItem = self.accountButton;
    
    // 6. Style sidebar
    self.menuViewController.view.layer.cornerRadius = 15;
    self.menuViewController.view.clipsToBounds = YES;
}

- (void)openAccountManager {
    AccountListViewController *vc = [AccountListViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationPopover;
    nav.popoverPresentationController.barButtonItem = self.accountButton;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)toggleSidebar {
    self.isSidebarExpanded = !self.isSidebarExpanded;
    CGFloat newWidth = self.isSidebarExpanded ? 280 : 70;
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.sidebarWidthConstraint.constant = newWidth;
        [self.view layoutIfNeeded];
    } completion:nil];
    
    // Notify the menu to update its cells
    [self.menuViewController.tableView reloadData];
}

- (void)navigateToViewController:(UIViewController *)viewController {
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
