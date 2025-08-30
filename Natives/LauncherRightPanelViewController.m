#import "LauncherRightPanelViewController.h"
#import "authenticator/BaseAuthenticator.h"
#import "AccountListViewController.h"
#import "LauncherPreferences.h"
#import "UIImageView+AFNetworking.h"
#import "utils.h"
#import "PLProfiles.h"
#import "PickTextField.h"
#import "PLPickerView.h"

// Define the global variable that was previously in LauncherNavigationController.m
NSMutableArray<NSDictionary *> *localVersionList;

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

    [self setupShareButton];
    [self setupAccountUI];
    [self setupLaunchUI];
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
    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 60; // Make it circular
    self.avatarImageView.userInteractionEnabled = YES;
    [self.view addSubview:self.avatarImageView];

    self.playerNameLabel = [[UILabel alloc] init];
    self.playerNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.playerNameLabel.font = [UIFont boldSystemFontOfSize:18];
    self.playerNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.playerNameLabel];

    self.accountTypeLabel = [[UILabel alloc] init];
    self.accountTypeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.accountTypeLabel.font = [UIFont systemFontOfSize:14];
    self.accountTypeLabel.textColor = [UIColor secondaryLabelColor];
    self.accountTypeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.accountTypeLabel];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectAccount:)];
    [self.avatarImageView addGestureRecognizer:tapGesture];
}

- (void)setupLaunchUI {
    self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.playButton setTitle:localize(@"Play", nil) forState:UIControlStateNormal];
    self.playButton.backgroundColor = [UIColor colorWithRed:54/255.0 green:176/255.0 blue:48/255.0 alpha:1.0];
    self.playButton.layer.cornerRadius = 8;
    self.playButton.tintColor = UIColor.whiteColor;
    [self.playButton addTarget:self action:@selector(launchMinecraft:) forControlEvents:UIControlEventPrimaryActionTriggered];
    [self.view addSubview:self.playButton];

    self.versionTextField = [[PickTextField alloc] init];
    self.versionTextField.translatesAutoresizingMaskIntoConstraints = NO;
    self.versionTextField.placeholder = @"Specify version...";
    self.versionTextField.leftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    self.versionTextField.rightView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"SpinnerArrow"] _imageWithSize:CGSizeMake(30, 30)]];
    self.versionTextField.leftViewMode = UITextFieldViewModeAlways;
    self.versionTextField.rightViewMode = UITextFieldViewModeAlways;
    self.versionTextField.textAlignment = NSTextAlignmentCenter;
    self.versionTextField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.versionTextField];

    self.versionPickerView = [[PLPickerView alloc] init];
    self.versionPickerView.delegate = self;
    self.versionPickerView.dataSource = self;
    UIToolbar *versionPickToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    UIBarButtonItem *versionFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *versionDoneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(versionClosePicker)];
    versionPickToolbar.items = @[versionFlexibleSpace, versionDoneButton];
    self.versionTextField.inputAccessoryView = versionPickToolbar;
    self.versionTextField.inputView = self.versionPickerView;
}

- (void)setupLayoutConstraints {
    [NSLayoutConstraint activateConstraints:@[
        // Share Button
        [self.shareButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.shareButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.shareButton.widthAnchor constraintEqualToConstant:44],
        [self.shareButton.heightAnchor constraintEqualToConstant:44],

        // Account UI
        [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-100],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:120],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:120],

        [self.playerNameLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:16],
        [self.playerNameLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.playerNameLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [self.accountTypeLabel.topAnchor constraintEqualToAnchor:self.playerNameLabel.bottomAnchor constant:4],
        [self.accountTypeLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.accountTypeLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        
        // Launch UI
        [self.playButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.playButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.playButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.playButton.heightAnchor constraintEqualToConstant:50],
        
        [self.versionTextField.bottomAnchor constraintEqualToAnchor:self.playButton.topAnchor constant:-16],
        [self.versionTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.versionTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.versionTextField.heightAnchor constraintEqualToConstant:44],
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

#pragma mark - Account Logic

- (void)selectAccount:(UITapGestureRecognizer *)sender {
    AccountListViewController *vc = [[AccountListViewController alloc] init];
    vc.whenDelete = ^void(NSString* name) {
        if ([name isEqualToString:getPrefObject(@"internal.selected_account")]) {
            BaseAuthenticator.current = nil;
            setPrefObject(@"internal.selected_account", @"");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountChanged" object:nil];
        }
    };
    vc.whenItemSelected = ^void() {
        setPrefObject(@"internal.selected_account", BaseAuthenticator.current.authData[@"username"]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AccountChanged" object:nil];
    };
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.preferredContentSize = CGSizeMake(350, 250);

    UIPopoverPresentationController *popoverController = vc.popoverPresentationController;
    popoverController.sourceView = self.avatarImageView;
    popoverController.sourceRect = self.avatarImageView.bounds;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popoverController.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)updateAccountInfo {
    NSDictionary *selected = BaseAuthenticator.current.authData;

    if (selected == nil) {
        self.playerNameLabel.text = localize(@"login.option.select", nil);
        self.accountTypeLabel.text = @"";
        self.avatarImageView.image = [UIImage imageNamed:@"DefaultAccount"];
        return;
    }

    BOOL isDemo = [selected[@"username"] hasPrefix:@"Demo."];
    self.playerNameLabel.text = [selected[@"username"] substringFromIndex:(isDemo ? 5 : 0)];

    BOOL shouldUpdateProfiles = (getenv("DEMO_LOCK") != NULL) != isDemo;

    unsetenv("DEMO_LOCK");
    setenv("POJAV_GAME_DIR", [NSString stringWithFormat:@"%s/Library/Application Support/minecraft", getenv("POJAV_HOME")].UTF8String, 1);

    if (isDemo) {
        self.accountTypeLabel.text = localize(@"login.option.demo", nil);
        setenv("DEMO_LOCK", "1", 1);
        setenv("POJAV_GAME_DIR", [NSString stringWithFormat:@"%s/.demo", getenv("POJAV_HOME")].UTF8String, 1);
    } else if (selected[@"xboxGamertag"] == nil) {
        self.accountTypeLabel.text = localize(@"login.option.local", nil);
    } else {
        self.accountTypeLabel.text = selected[@"xboxGamertag"];
    }

    NSURL *url = [NSURL URLWithString:[selected[@"profilePicURL"] stringByReplacingOccurrencesOfString:@"\\" withString:@"/"]];
    UIImage *placeholder = [UIImage imageNamed:@"DefaultAccount"];
    [self.avatarImageView setImageWithURL:url placeholderImage:placeholder];

    if (shouldUpdateProfiles) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ProfilesNeedUpdate" object:nil];
    }
}

#pragma mark - Launch Logic

- (void)launchMinecraft:(UIButton *)sender {
    if (!self.versionTextField.hasText) {
        [self.versionTextField becomeFirstResponder];
        return;
    }

    if (BaseAuthenticator.current == nil) {
        [self selectAccount:nil];
        return;
    }
    
    NSString *versionId = PLProfiles.current.profiles[self.versionTextField.text][@"lastVersionId"];
    NSString *message = [NSString stringWithFormat:@"Launching version: %@", versionId];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Launch" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadProfileList {
    [self fetchLocalVersionList];
    [PLProfiles updateCurrent];
    [self.versionPickerView reloadAllComponents];
    
    self.profileSelectedAt = [PLProfiles.current.profiles.allKeys indexOfObject:PLProfiles.current.selectedProfileName];
    if (self.profileSelectedAt == -1 && PLProfiles.current.profiles.count > 0) {
        self.profileSelectedAt = 0;
    }
    
    if (self.profileSelectedAt != -1) {
        [self.versionPickerView selectRow:self.profileSelectedAt inComponent:0 animated:NO];
        [self pickerView:self.versionPickerView didSelectRow:self.profileSelectedAt inComponent:0];
    }
}

- (void)fetchLocalVersionList {
    if (!localVersionList) {
        localVersionList = [NSMutableArray new];
    }
    [localVersionList removeAllObjects];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *versionPath = [NSString stringWithFormat:@"%s/versions/", getenv("POJAV_GAME_DIR")];
    NSArray *list = [fileManager contentsOfDirectoryAtPath:versionPath error:Nil];
    for (NSString *versionId in list) {
        NSString *localPath = [NSString stringWithFormat:@"%@/%@", versionPath, versionId];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:localPath isDirectory:&isDirectory] && isDirectory) {
            [localVersionList addObject:@{
                @"id": versionId,
                @"type": @"custom"
            }];
        }
    }
}

#pragma mark - UIPickerView

- (void)versionClosePicker {
    [self.versionTextField endEditing:YES];
    [self pickerView:self.versionPickerView didSelectRow:[self.versionPickerView selectedRowInComponent:0] inComponent:0];
}

- (void)pickerView:(PLPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row < 0 || row >= PLProfiles.current.profiles.count) return;
    self.profileSelectedAt = row;
    ((UIImageView *)self.versionTextField.leftView).image = [pickerView imageAtRow:row column:component];
    self.versionTextField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    PLProfiles.current.selectedProfileName = self.versionTextField.text;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return PLProfiles.current.profiles.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row < 0 || row >= PLProfiles.current.profiles.allValues.count) return @"";
    return PLProfiles.current.profiles.allValues[row][@"name"];
}

- (void)pickerView:(PLPickerView *)pickerView enumerateImageView:(UIImageView *)imageView forRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row < 0 || row >= PLProfiles.current.profiles.allValues.count) return;
    UIImage *fallbackImage = [[UIImage imageNamed:@"DefaultProfile"] _imageWithSize:CGSizeMake(40, 40)];
    NSString *urlString = PLProfiles.current.profiles.allValues[row][@"icon"];
    [imageView setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:fallbackImage];
}

#pragma mark - UIPopoverPresentationControllerDelegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end
