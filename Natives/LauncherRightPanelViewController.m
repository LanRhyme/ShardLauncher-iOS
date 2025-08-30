#import "LauncherRightPanelViewController.h"
#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "LauncherPreferences.h"
#import "UIImageView+AFNetworking.h"
#import "utils.h"
#import "PLProfiles.h"
#import "PickTextField.h"
#import "PLPickerView.h"
#import "LauncherNavigationController.h"

@interface LauncherRightPanelViewController () <UIPickerViewDataSource, PLPickerViewDelegate, UIPopoverPresentationControllerDelegate>

// Account UI
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *playerNameLabel;
@property (nonatomic, strong) UILabel *accountTypeLabel;

// Launch UI
@property(nonatomic) PLPickerView* versionPickerView;
@property(nonatomic) UITextField* versionTextField;
@property(nonatomic) UIButton* playButton;
@property(nonatomic) int profileSelectedAt;

// Share Button
@property (nonatomic, strong) UIButton *shareButton;

@end

@implementation LauncherRightPanelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupAccountUI];
    [self setupLaunchUI];
    [self setupShareButton];
    [self setupLayoutConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccountInfo) name:@"AccountChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadProfileList) name:@"ProfilesNeedUpdate" object:nil];

    [self updateAccountInfo];
    [self reloadProfileList];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UI Setup

- (void)setupShareButton {
    self.shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.shareButton setImage:[UIImage systemImageNamed:@"square.and.arrow.up"] forState:UIControlStateNormal];
    [self.shareButton addTarget:self action:@selector(shareLogFile:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shareButton];
}

- (void)setupAccountUI {
    // ... (implementation unchanged)
}

- (void)setupLaunchUI {
    // ... (implementation unchanged)
}

- (void)setupLayoutConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // Share Button
        [self.shareButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.shareButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.shareButton.widthAnchor constraintEqualToConstant:44],
        [self.shareButton.heightAnchor constraintEqualToConstant:44],

        // Account UI
        // ... (constraints unchanged)
        
        // Launch UI
        // ... (constraints unchanged)
    ]];
}

#pragma mark - Actions

- (void)shareLogFile:(UIButton *)sender {
    NSString *latestlogPath = [NSString stringWithFormat:@"file://%s/latestlog.old.txt", getenv("POJAV_HOME")];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:latestlogPath]] applicationActivities:nil];
    activityVC.popoverPresentationController.sourceView = sender;
    activityVC.popoverPresentationController.sourceRect = sender.bounds;
    [self presentViewController:activityVC animated:YES completion:nil];
}

// ... (rest of the account and launch logic is unchanged)

@end
