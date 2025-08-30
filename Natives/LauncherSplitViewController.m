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

    // Create colored circles that will be blurred.
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

    // Create a strong blur effect to apply to the circles.
    UIBlurEffect *strongBlurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterial];

    // Create a blur view for the top left circle.
    UIVisualEffectView *topLeftBlurView = [[UIVisualEffectView alloc] initWithEffect:strongBlurEffect];
    topLeftBlurView.frame = topLeftCircle.frame;
    topLeftBlurView.layer.cornerRadius = circleSize / 2.0;
    topLeftBlurView.clipsToBounds = YES;
    [self.view insertSubview:topLeftBlurView atIndex:2];

    // Create a blur view for the bottom right circle.
    UIVisualEffectView *bottomRightBlurView = [[UIVisualEffectView alloc] initWithEffect:strongBlurEffect];
    bottomRightBlurView.frame = bottomRightCircle.frame;
    bottomRightBlurView.layer.cornerRadius = circleSize / 2.0;
    bottomRightBlurView.clipsToBounds = YES;
    bottomRightBlurView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view insertSubview:bottomRightBlurView atIndex:3];

    if (@available(iOS 14.0, *)) {
        self.preferredDisplayMode = UISplitViewControllerDisplayModeTwoBesideSecondary;
        self.preferredPrimaryColumnWidthFraction = 0.10;
        self.preferredSupplementaryColumnWidthFraction = 0.65;
    } else {
        // Fallback on earlier versions
        self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
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
