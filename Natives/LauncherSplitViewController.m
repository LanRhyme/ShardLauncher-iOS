#import "LauncherSplitViewController.h"
#import "MainContentViewController.h"
#import "LauncherRightPanelViewController.h"

@interface LauncherSplitViewController () <UISplitViewControllerDelegate>

@end

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.preferredPrimaryColumnWidthFraction = 0.7;
    self.maximumPrimaryColumnWidth = self.view.bounds.size.width * 0.7;
    self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
    self.preferredSplitBehavior = UISplitViewControllerSplitBehaviorTile;

    MainContentViewController *mainContentViewController = [[MainContentViewController alloc] init];
    LauncherRightPanelViewController *rightPanelViewController = [[LauncherRightPanelViewController alloc] init];

    self.viewControllers = @[mainContentViewController, rightPanelViewController];

    self.delegate = self;
}

@end
