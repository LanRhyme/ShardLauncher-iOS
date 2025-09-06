#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "AFNetworking.h"
#import "ALTServerConnection.h"
#import "LauncherNavigationController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherOnlineViewController.h"
#import "LauncherPreferences.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherProfilesViewController.h"
#import "PLProfiles.h"
#import "UIButton+AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "UIKit+hook.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

#include <dlfcn.h>

@implementation LauncherMenuCustomItem

+ (LauncherMenuCustomItem *)title:(NSString *)title imageName:(NSString *)imageName action:(id)action {
    LauncherMenuCustomItem *item = [[LauncherMenuCustomItem alloc] init];
    item.title = title;
    item.imageName = imageName;
    item.action = action;
    return item;
}

+ (LauncherMenuCustomItem *)vcClass:(Class)class {
    id vc = [class new];
    LauncherMenuCustomItem *item = [[LauncherMenuCustomItem alloc] init];
    item.title = [vc title];
    item.imageName = [vc imageName];
    // View controllers are put into an array to keep its state
    item.vcArray = @[vc];
    return item;
}

@end

@interface LauncherMenuViewController()
@property(nonatomic) NSMutableArray<LauncherMenuCustomItem*> *options;
@property(nonatomic) int lastSelectedIndex;
@property(nonatomic) BOOL isSidebarCollapsed;
@end

@implementation LauncherMenuViewController

#define contentNavigationController ((LauncherNavigationController *)self.splitViewController.viewControllers[1])

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isInitialVc = YES;
    self.isSidebarCollapsed = YES; // Start collapsed
    
    // Remove title view, as it takes up space
    self.navigationItem.titleView = nil;
    self.navigationItem.title = @"";

    // Add expand/collapse button
    UIBarButtonItem *toggleButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"sidebar.right"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleSidebar:)];
    self.navigationItem.leftBarButtonItem = toggleButton;
    
    self.options = @[
        [LauncherMenuCustomItem vcClass:LauncherNewsViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherOnlineViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherProfilesViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherPreferencesViewController.class],
    ].mutableCopy;
    if (realUIIdiom != UIUserInterfaceIdiomTV) {
        [self.options addObject:(id)[LauncherMenuCustomItem
                                     title:localize(@"launcher.menu.custom_controls", nil)
                                     imageName:@"MenuCustomControls" action:^{
            [contentNavigationController performSelector:@selector(enterCustomControls)];
        }]];
    }
    [self.options addObject:
     (id)[LauncherMenuCustomItem
          title:localize(@"launcher.menu.execute_jar", nil)
          imageName:@"MenuInstallJar" action:^{
        [contentNavigationController performSelector:@selector(enterModInstaller)];
    }]];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationController.toolbarHidden = YES; // Hide the old toolbar
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self restoreHighlightedSelection];
}

- (void)toggleSidebar:(id)sender {
    self.isSidebarCollapsed = !self.isSidebarCollapsed;
    
    // Animate the width change
    [UIView animateWithDuration:0.3 animations:^{
        self.splitViewController.preferredPrimaryColumnWidth = self.isSidebarCollapsed ? 80 : 240;
    }];
    
    // Update button icon
    NSString *iconName = self.isSidebarCollapsed ? @"sidebar.right" : @"sidebar.left";
    ((UIBarButtonItem *)sender).image = [UIImage systemImageNamed:iconName];
    
    // Reload table to show/hide text
    [self.tableView reloadData];
    [self restoreHighlightedSelection];
}

- (void)restoreHighlightedSelection {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.lastSelectedIndex inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }

    // Show/hide text based on collapsed state
    if (self.isSidebarCollapsed) {
        cell.textLabel.text = @"";
    } else {
        cell.textLabel.text = [self.options[indexPath.row] title];
    }
    
    // Use a dynamic color for the icons
    UIColor *iconColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:0.4 green:0.8 blue:0.4 alpha:1.0]; // Deep Green
        } else {
            return [UIColor colorWithRed:0.6 green:1.0 blue:0.6 alpha:1.0]; // Light Green
        }
    }];
    
    UIImage *origImage = [UIImage imageNamed:[self.options[indexPath.row] imageName]];
    if (!origImage) {
        origImage = [UIImage systemImageNamed:[self.options[indexPath.row] imageName]];
    }
    
    cell.imageView.image = [origImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.tintColor = iconColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LauncherMenuCustomItem *selected = self.options[indexPath.row];
    
    if (selected.action != nil) {
        [self restoreHighlightedSelection];
        selected.action();
    } else {
        if(self.isInitialVc) {
            self.isInitialVc = NO;
        } else {
            self.options[self.lastSelectedIndex].vcArray = contentNavigationController.viewControllers;
            
            // Animate the view controller transition
            [UIView transitionWithView:contentNavigationController.view
                              duration:0.3
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                [contentNavigationController setViewControllers:selected.vcArray animated:NO];
                            } completion:nil];

            self.lastSelectedIndex = (int)indexPath.row;
        }
    }
}

// Removed drawAccountButton, updateAccountInfo, selectAccount as they are moved to RightPaneViewController
// Removed JIT-related code as it's not relevant to the menu UI itself

@end
