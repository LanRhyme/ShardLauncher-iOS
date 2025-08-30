#import "FabricInstallViewController.h"
#import "FabricUtils.h"
#import "utils.h"

@interface FabricInstallViewController ()
@property(nonatomic) FabricUtils *fabric;
@property(nonatomic) NSMutableArray<NSString *> *versionList;
@property(nonatomic) UIActivityIndicatorView *indicator;
@property(nonatomic) int selectedVersion;
@end

@implementation FabricInstallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Fabric Installer";
    self.tableView.allowsMultipleSelection = YES;
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.indicator.center = self.view.center;
    [self.view addSubview:self.indicator];
    
    self.fabric = [FabricUtils new];
    self.versionList = [NSMutableArray new];
    
    [self.indicator startAnimating];
    [self.fabric fetchVersionsWithCallback:^(NSError *err) {
        [self.indicator stopAnimating];
        if (err) {
            showDialog(localize(@"Error", nil), err.localizedDescription);
            return;
        }
        [self.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fabric.versions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    NSDictionary *version = self.fabric.versions[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Minecraft %@", version[@"game_version"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Loader %@", version[@"version"]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedVersion = indexPath.row;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:localize(@"Install", nil)
                                                                     message:[NSString stringWithFormat:@"Install Fabric for Minecraft %@?", self.fabric.versions[self.selectedVersion][@"game_version"]]
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:localize(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:localize(@"Install", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self doInstall];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doInstall {
    [self.indicator startAnimating];
    [self.fabric installVersion:self.selectedVersion withCallback:^(NSString *versionName, NSError *err) {
        [self.indicator stopAnimating];
        if (err) {
            showDialog(localize(@"Error", nil), err.localizedDescription);
            return;
        }
        
        // Instead of modifying the global list directly,
        // post a notification to inform other parts of the app to update.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProfilesNeedUpdate" object:nil];
        
        showDialog(localize(@"Success", nil), [NSString stringWithFormat:@"Successfully installed Fabric for Minecraft %@", versionName]);
    }];
}

@end
