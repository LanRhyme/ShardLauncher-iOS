#import "FabricInstallViewController.h"
#import "FabricUtils.h"
#import "utils.h" // Re-importing for the showDialog function

@interface FabricInstallViewController ()
@property(nonatomic) FabricUtils *fabric;
@property(nonatomic) UIActivityIndicatorView *indicator;
@property(nonatomic) NSInteger selectedVersion;
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
    
    NSDictionary *version = self.fabric.versions[self.selectedVersion];
    NSString *message = [NSString stringWithFormat:@"Install Fabric for Minecraft %@?", version[@"game_version"]];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:localize(@"Install", nil)
                                                                     message:message
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
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProfilesNeedUpdate" object:nil];
        
        NSString *successMessage = [NSString stringWithFormat:@"Successfully installed Fabric for Minecraft %@", versionName];
        showDialog(localize(@"Success", nil), successMessage);
    }];
}

@end
