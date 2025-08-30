#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
#import "MainContentViewController.h"
#import "LauncherRightPanelViewController.h"

@interface LauncherSplitViewController ()

@end

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;

    if (@available(iOS 14.0, *)) {
        self.preferredPrimaryColumnWidthFraction = 0.20;
        self.preferredSupplementaryColumnWidthFraction = 0.55;
    }
    
    LauncherMenuViewController *menuViewController = [[LauncherMenuViewController alloc] init];
    MainContentViewController *mainContentViewController = [[MainContentViewController alloc] init];
    LauncherRightPanelViewController *rightPanelViewController = [[LauncherRightPanelViewController alloc] init];

    if (@available(iOS 14.0, *)) {
        [self setViewController:menuViewController forColumn:UISplitViewControllerColumnPrimary];
        [self setViewController:mainContentViewController forColumn:UISplitViewControllerColumnSupplementary];
        [self setViewController:rightPanelViewController forColumn:UISplitViewControllerColumnSecondary];
    } else {
        // Fallback on earlier versions
        self.viewControllers = @[menuViewController, mainContentViewController, rightPanelViewController];
    }
}

- (instancetype)initWithStyle:(UISplitViewControllerStyle)style {
    if (@available(iOS 14.0, *)) {
        self = [super initWithStyle:UISplitViewControllerStyleTripleColumn];
    } else {
        self = [super initWithStyle:style];
    }
    return self;
}

@end
