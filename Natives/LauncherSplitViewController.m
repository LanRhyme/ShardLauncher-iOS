#import "LauncherSplitViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "utils.h"
#import "UIKit+hook.h"

#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "PLProfiles.h"
#import "PickTextField.h"
#import "PLPickerView.h"
#import "UIImageView+AFNetworking.h"

// MARK: - RightPaneViewController Definition

@interface RightPaneViewController : UIViewController <UIPickerViewDataSource, PLPickerViewDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *accountTypeLabel;
@property (nonatomic, strong) UIButton *accountButton;
@property (nonatomic, strong) UITextField *profileTextField;
@property (nonatomic, strong) PLPickerView *profilePickerView;
@property (nonatomic, strong) UIButton *launchButton;
@property (nonatomic, strong) UIButton *shareLogButton;

@end

@implementation RightPaneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    [self setupUI];
    [self updateAccountInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadProfileList) name:@"ProfileListChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccountInfo) name:@"AuthInfoChanged" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
    self.avatarImageView = [UIImageView new];
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.layer.cornerRadius = 12.0;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.avatarImageView];

    self.usernameLabel = [UILabel new];
    self.usernameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    self.usernameLabel.textAlignment = NSTextAlignmentCenter;
    self.usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.usernameLabel];

    self.accountTypeLabel = [UILabel new];
    self.accountTypeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.accountTypeLabel.textColor = [UIColor secondaryLabelColor];
    self.accountTypeLabel.textAlignment = NSTextAlignmentCenter;
    self.accountTypeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.accountTypeLabel];

    self.accountButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.accountButton addTarget:self action:@selector(selectAccount:) forControlEvents:UIControlEventTouchUpInside];
    self.accountButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.accountButton];

    self.shareLogButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.shareLogButton setImage:[UIImage systemImageNamed:@"square.and.arrow.up"] forState:UIControlStateNormal];
    [self.shareLogButton addTarget:self action:@selector(shareLogs:) forControlEvents:UIControlEventTouchUpInside];
    self.shareLogButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.shareLogButton];

    self.launchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.launchButton setTitle:localize(@"Play", nil) forState:UIControlStateNormal];
    self.launchButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.launchButton.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    self.launchButton.tintColor = UIColor.whiteColor;
    self.launchButton.layer.cornerRadius = 8;
    [self.launchButton addTarget:self action:@selector(launchGame:) forControlEvents:UIControlEventTouchUpInside];
    self.launchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.launchButton];

    self.profileTextField = [[PickTextField alloc] init];
    self.profileTextField.placeholder = @"Select a profile...";
    self.profileTextField.textAlignment = NSTextAlignmentCenter;
    self.profileTextField.leftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.profileTextField.leftViewMode = UITextFieldViewModeAlways;
    self.profileTextField.rightView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"SpinnerArrow"] _imageWithSize:CGSizeMake(30, 30)]];
    self.profileTextField.rightViewMode = UITextFieldViewModeAlways;
    self.profileTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.profileTextField];

    self.profilePickerView = [[PLPickerView alloc] init];
    self.profilePickerView.delegate = self;
    self.profilePickerView.dataSource = self;
    self.profileTextField.inputView = self.profilePickerView;

    UILayoutGuide *margins = self.view.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[        [self.shareLogButton.topAnchor constraintEqualToAnchor:margins.topAnchor constant:8],
        [self.shareLogButton.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor constant:-8],
        [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-100],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:80],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:80],
        [self.usernameLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:12],
        [self.usernameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.usernameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.accountTypeLabel.topAnchor constraintEqualToAnchor:self.usernameLabel.bottomAnchor constant:4],
        [self.accountTypeLabel.leadingAnchor constraintEqualToAnchor:self.usernameLabel.leadingAnchor],
        [self.accountTypeLabel.trailingAnchor constraintEqualToAnchor:self.usernameLabel.trailingAnchor],
        [self.accountButton.topAnchor constraintEqualToAnchor:self.avatarImageView.topAnchor],
        [self.accountButton.leadingAnchor constraintEqualToAnchor:self.avatarImageView.leadingAnchor],
        [self.accountButton.trailingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor],
        [self.accountButton.bottomAnchor constraintEqualToAnchor:self.accountTypeLabel.bottomAnchor],
        [self.launchButton.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor constant:-20],
        [self.launchButton.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor constant:16],
        [self.launchButton.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor constant:-16],
        [self.launchButton.heightAnchor constraintEqualToConstant:50],
        [self.profileTextField.bottomAnchor constraintEqualToAnchor:self.launchButton.topAnchor constant:-16],
        [self.profileTextField.leadingAnchor constraintEqualToAnchor:self.launchButton.leadingAnchor],
        [self.profileTextField.trailingAnchor constraintEqualToAnchor:self.launchButton.trailingAnchor],
        [self.profileTextField.heightAnchor constraintEqualToConstant:44],
    ]];
}

- (void)updateAccountInfo {
    NSDictionary *selected = BaseAuthenticator.current.authData;
    if (selected == nil) {
        self.usernameLabel.text = localize(@"login.option.select", nil);
        self.accountTypeLabel.text = @"";
        self.avatarImageView.image = [UIImage imageNamed:@"DefaultAccount"];
        return;
    }

    BOOL isDemo = [selected[@"username"] hasPrefix:@"Demo."];
    self.usernameLabel.text = [selected[@"username"] substringFromIndex:(isDemo ? 5 : 0)];

    if (isDemo) {
        self.accountTypeLabel.text = localize(@"login.option.demo", nil);
    } else if (selected[@"xboxGamertag"] == nil) {
        self.accountTypeLabel.text = localize(@"login.option.local", nil);
    } else {
        self.accountTypeLabel.text = selected[@"xboxGamertag"];
    }

    NSString *uuid = selected[@"uuid"];
    NSURL *avatarURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://crafatar.com/avatars/%@?size=128&overlay", uuid]];
    UIImage *placeholder = [UIImage imageNamed:@"DefaultAccount"];
    [self.avatarImageView setImageWithURL:avatarURL placeholderImage:placeholder];
}

- (void)selectAccount:(UIButton *)sender {
    AccountListViewController *vc = [[AccountListViewController alloc] init];
    vc.whenDelete = ^void(NSString* name) {
        if ([name isEqualToString:getPrefObject(@"internal.selected_account")]) {
            BaseAuthenticator.current = nil;
            setPrefObject(@"internal.selected_account", @"");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AuthInfoChanged" object:nil];
        }
    };
    vc.whenItemSelected = ^void() {
        setPrefObject(@"internal.selected_account", BaseAuthenticator.current.authData[@"username"]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AuthInfoChanged" object:nil];
    };
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);

    UIPopoverPresentationController *popoverController = vc.popoverPresentationController;
    popoverController.sourceView = sender;
    popoverController.sourceRect = sender.bounds;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverController.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)shareLogs:(UIButton *)sender {
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("POJAV_HOME")];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:latestlogPath]] applicationActivities:nil];
    activityVC.popoverPresentationController.sourceView = sender;
    activityVC.popoverPresentationController.sourceRect = sender.bounds;
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)launchGame:(UIButton *)sender {
    LauncherNavigationController *contentNav = (LauncherNavigationController*)self.splitViewController.viewControllers[1];
    [contentNav performSelector:@selector(performInstallOrShowDetails:) withObject:sender];
}

- (void)reloadProfileList {
    [self.profilePickerView reloadAllComponents];
    NSInteger selectedRow = [PLProfiles.current.profiles.allKeys indexOfObject:PLProfiles.current.selectedProfileName];
    if (selectedRow != NSNotFound) {
        [self.profilePickerView selectRow:selectedRow inComponent:0 animated:NO];
        [self pickerView:self.profilePickerView didSelectRow:selectedRow inComponent:0];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return PLProfiles.current.profiles.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row >= PLProfiles.current.profiles.allValues.count) return @"Error";
    return PLProfiles.current.profiles.allValues[row][@"name"];
}

- (void)pickerView:(PLPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row >= PLProfiles.current.profiles.allValues.count) return;
    self.profileTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    PLProfiles.current.selectedProfileName = self.profileTextField.text;
    
    UIImageView *iconView = (UIImageView *)self.profileTextField.leftView;
    iconView.image = [pickerView imageAtRow:row column:component];
}

- (void)pickerView:(PLPickerView *)pickerView enumerateImageView:(UIImageView *)imageView forRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row >= PLProfiles.current.profiles.allValues.count) return;
    UIImage *fallbackImage = [[UIImage imageNamed:@"DefaultProfile"] _imageWithSize:CGSizeMake(40, 40)];
    NSString *urlString = PLProfiles.current.profiles.allValues[row][@"icon"];
    [imageView setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:fallbackImage];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end

// MARK: - LauncherSplitViewController Implementation

@implementation LauncherSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    LauncherMenuViewController *menuVc = [[LauncherMenuViewController alloc] init];
    UINavigationController *menuNav = [[UINavigationController alloc] initWithRootViewController:menuVc];

    LauncherNewsViewController *newsVc = [[LauncherNewsViewController alloc] init];
    LauncherNavigationController *contentNav = [[LauncherNavigationController alloc] initWithRootViewController:newsVc];
    contentNav.navigationBarHidden = YES;
    contentNav.toolbarHidden = YES;

    RightPaneViewController *rightPaneVc = [[RightPaneViewController alloc] init];

    if (@available(iOS 14.0, *)) {
        // Correct Order: [Primary, Supplementary, Secondary]
        self.viewControllers = @[menuNav, contentNav, rightPaneVc];
        
        self.preferredSplitBehavior = UISplitViewControllerSplitBehaviorTile;
        self.preferredDisplayMode = UISplitViewControllerDisplayModeTwoBesideSecondary;
        
        // Set widths
        self.preferredPrimaryColumnWidth = 80;
        // Set supplementary (middle) width to force the secondary (right) to be ~30%
        self.preferredSupplementaryColumnWidth = self.view.bounds.size.width * 0.7 - 80;

    } else {
        self.viewControllers = @[menuNav, contentNav];
    }
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
