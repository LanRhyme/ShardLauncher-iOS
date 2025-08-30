#import "LauncherMenuViewController.h"
#import "MainContentViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherOnlineViewController.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherProfilesViewController.h"
#import "LauncherNavigationController.h"
#import "utils.h"

@implementation LauncherMenuCustomItem
// ... (rest of the implementation is unchanged)
@end

@interface LauncherMenuViewController()
@property(nonatomic) NSMutableArray<LauncherMenuCustomItem*> *options;
@property(nonatomic) int lastSelectedIndex;
@end

@implementation LauncherMenuViewController

- (MainContentViewController *)mainContentViewController {
    if ([self.parentViewController isKindOfClass:[MainContentViewController class]]) {
        return (MainContentViewController *)self.parentViewController;
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;

    // The title view is now managed by the parent MainContentViewController
    self.navigationItem.titleView = nil;
    
    self.options = @[
        [LauncherMenuCustomItem vcClass:LauncherNewsViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherOnlineViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherProfilesViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherPreferencesViewController.class],
    ].mutableCopy;
    
    // Other menu items can be added here as before...

    // Select the first item by default
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self restoreHighlightedSelection];
}

- (void)restoreHighlightedSelection {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.lastSelectedIndex inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView = [UIView new];
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [UIColor systemFillColor];
        cell.selectedBackgroundView.layer.cornerRadius = 8;
    }

    LauncherMenuCustomItem *item = self.options[indexPath.row];
    
    // Show text only when expanded
    if ([self mainContentViewController] && [self mainContentViewController].isSidebarExpanded) {
        cell.textLabel.text = item.title;
    } else {
        cell.textLabel.text = @"";
    }

    UIImage *origImage = [UIImage systemImageNamed:item.imageName] ?: [UIImage imageNamed:item.imageName];
    cell.imageView.image = [origImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.imageView.tintColor = [UIColor labelColor];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.lastSelectedIndex = indexPath.row;
    LauncherMenuCustomItem *selected = self.options[indexPath.row];
    
    if (selected.action) {
        selected.action();
    } else if (selected.vcArray.firstObject) {
        // Use the new navigation method with animation
        [[self mainContentViewController] navigateToViewController:selected.vcArray.firstObject];
    }
}

@end
