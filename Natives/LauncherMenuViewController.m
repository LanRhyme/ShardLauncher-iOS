#import "LauncherMenuViewController.h"
#import "MainContentViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherOnlineViewController.h"
#import "LauncherPreferencesViewController.h"
#import "LauncherProfilesViewController.h"
#import "LauncherNavigationController.h"
#import "utils.h"

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
    item.vcArray = @[vc];
    return item;
}

@end

@interface LauncherMenuViewController()
@property(nonatomic) NSMutableArray<LauncherMenuCustomItem*> *options;
@property(nonatomic) int lastSelectedIndex;
@end

@implementation LauncherMenuViewController

- (UIBarButtonItem *)drawAccountButton {
    return self.navigationItem.rightBarButtonItem;
}

- (void)fetchLocalVersionList {
    [self.tableView reloadData];
}

- (MainContentViewController *)mainContentViewController {
    if (@available(iOS 14.0, *)) {
        UIViewController *vc = [self.splitViewController viewControllerForColumn:UISplitViewControllerColumnSupplementary];
        if ([vc isKindOfClass:[MainContentViewController class]]) {
            return (MainContentViewController *)vc;
        } else if ([vc isKindOfClass:[UINavigationController class]]) {
            return ((UINavigationController *)vc).viewControllers.firstObject;
        }
    } else {
        for (UIViewController *vc in self.splitViewController.viewControllers) {
            if ([vc isKindOfClass:[MainContentViewController class]]) {
                return (MainContentViewController *)vc;
            } else if ([vc isKindOfClass:[UINavigationController class]]) {
                UINavigationController *nav = (UINavigationController *)vc;
                if ([nav.viewControllers.firstObject isKindOfClass:[MainContentViewController class]]) {
                    return (MainContentViewController *)nav.viewControllers.firstObject;
                }
            }
        }
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;

    self.navigationItem.titleView = nil;
    
    self.options = @[
        [LauncherMenuCustomItem vcClass:LauncherNewsViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherOnlineViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherProfilesViewController.class],
        [LauncherMenuCustomItem vcClass:LauncherPreferencesViewController.class],
    ].mutableCopy;
    
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
    
    cell.textLabel.text = item.title;

    UIImage *origImage = [UIImage systemImageNamed:item.imageName] ?: [UIImage imageNamed:item.imageName];
    cell.imageView.image = [origImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.lastSelectedIndex = indexPath.row;
    LauncherMenuCustomItem *selected = self.options[indexPath.row];
    
    if (selected.action) {
        selected.action();
    } else if (selected.vcArray.firstObject) {
        MainContentViewController *mainVC = [self mainContentViewController];
        [mainVC navigateToViewController:selected.vcArray.firstObject];
        if (self.splitViewController.isCollapsed) {
            [self.splitViewController showDetailViewController:mainVC sender:self];
        }
    }
}

@end