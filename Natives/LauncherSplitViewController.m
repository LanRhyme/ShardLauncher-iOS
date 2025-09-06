#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "utils.h"

// MARK: - RightPaneViewController Definition

/// @brief This is the view controller for the new right-side pane.
/// It will contain the user avatar, launch controls, and other navigation elements.
@interface RightPaneViewController : UIViewController
@end

@implementation RightPaneViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Use a distinct background color to make the new pane visible during development.
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemGray6Color];
    } else {
        self.view.backgroundColor = [UIColor lightGrayColor];
    }

    // Placeholder label
    UILabel *placeholderLabel = [[UILabel alloc] init];
    placeholderLabel.text = @"Right Pane";
    placeholderLabel.textColor = [UIColor secondaryLabelColor];
    placeholderLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:placeholderLabel];

    [NSLayoutConstraint activateConstraints:@[[placeholderLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                              [placeholderLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]]];
}
@end

// MARK: - LauncherSplitViewController Implementation

@interface LauncherSplitViewController ()<UISplitViewControllerDelegate>{
}
@end

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = UIColor.systemBackgroundColor;
    }

    self.delegate = self;

    // 1. Create the view controllers for the three columns.
    LauncherMenuViewController *menuVc = [[LauncherMenuViewController alloc] init];
    UINavigationController *menuNav = [[UINavigationController alloc] initWithRootViewController:menuVc];

    // The main content view starts with the News page, wrapped in our custom navigation controller.
    LauncherNewsViewController *newsVc = [[LauncherNewsViewController alloc] init];
    LauncherNavigationController *contentNav = [[LauncherNavigationController alloc] initWithRootViewController:newsVc];
    
    // As requested, hide the navigation bar and toolbar from the main content area.
    // Their functionality will be moved to the right pane.
    contentNav.navigationBarHidden = YES;
    contentNav.toolbarHidden = YES;

    // The new right-side pane.
    RightPaneViewController *rightPaneVc = [[RightPaneViewController alloc] init];

    // 2. Set the view controllers for the triple-column layout.
    self.viewControllers = @[menuNav, contentNav, rightPaneVc];

    // 3. Configure column widths and behavior.
    // This behavior tiles all columns next to each other.
    self.preferredSplitBehavior = UISplitViewControllerSplitBehaviorTile;
    
    // This display mode ensures all three columns are visible when possible.
    if (@available(iOS 14.0, *)) {
        self.preferredDisplayMode = UISplitViewControllerDisplayModeTwoBesideSecondary;
    }
    
    // Set the right pane to be 30% of the screen width.
    self.preferredSecondaryColumnWidth = self.view.bounds.size.width * 0.3;
    
    // Set the primary column (menu) to a fixed width for the icon bar.
    self.preferredPrimaryColumnWidth = 80;
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
