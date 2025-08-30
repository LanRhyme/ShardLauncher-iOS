#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
#import "MainContentViewController.h"
#import "LauncherRightPanelViewController.h"

@interface LauncherSplitViewController ()

@end

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Use the system background color which adapts to light/dark mode
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // Create colored circles that will be blurred by the view on top.
    CGFloat circleSize = 400.0;
    UIView *topLeftCircle = [[UIView alloc] initWithFrame:CGRectMake(-circleSize/2, -circleSize/2, circleSize, circleSize)];
    topLeftCircle.backgroundColor = [UIColor.greenColor colorWithAlphaComponent:0.5];
    topLeftCircle.layer.cornerRadius = circleSize / 2.0;

    UIView *bottomRightCircle = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - circleSize/2, self.view.bounds.size.height - circleSize/2, circleSize, circleSize)];
    bottomRightCircle.backgroundColor = [UIColor.greenColor colorWithAlphaComponent:0.5];
    bottomRightCircle.layer.cornerRadius = circleSize / 2.0;
    bottomRightCircle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;

    [self.view insertSubview:topLeftCircle atIndex:0];
    [self.view insertSubview:bottomRightCircle atIndex:1];

    // Create a blur view to place over the circles, acting as a frosted glass effect for the entire background.
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.view.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurEffectView.alpha = 0.5; // As per user request for 50% transparency
    [self.view insertSubview:blurEffectView atIndex:2];

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
