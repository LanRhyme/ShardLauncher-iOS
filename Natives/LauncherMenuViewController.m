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
    
    if ([self mainContentViewController] && self.mainContentViewController.isSidebarExpanded) {
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
        [[self mainContentViewController] navigateToViewController:selected.vcArray.firstObject];
    }
}

@end
