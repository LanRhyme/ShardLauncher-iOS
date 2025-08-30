#import "LauncherOnlineViewController.h"
#import "ZeroTierBridge.h"

@interface LauncherOnlineViewController () <ZeroTierBridgeDelegate, UITableViewDataSource, UITableViewDelegate>

// UI Elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *createRoomButton;
@property (nonatomic, strong) UILabel *tutorialLabel;
@property (nonatomic, strong) UITextField *networkIdTextField;
@property (nonatomic, strong) UIButton *joinRoomButton;
@property (nonatomic, strong) UITableView *networksTableView;
@property (nonatomic, strong) UILabel *infoLabel;

// Data
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSDictionary *> *joinedNetworks;

@end

@implementation LauncherOnlineViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"联机 (ZeroTier)";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.joinedNetworks = [NSMutableDictionary new];

    [self setupUI];
    
    // Start ZeroTier Node
    [ZeroTierBridge sharedInstance].delegate = self;
    NSString *homePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"zerotier-one"];
    [[ZeroTierBridge sharedInstance] startNodeWithHomeDirectory:homePath];
    
    [self updateUIForConnectionState];
}

- (void)setupUI {
    // Status Label
    self.statusLabel = [UILabel new];
    self.statusLabel.text = @"ZT 节点: 正在初始化...";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // Create Room Button
    self.createRoomButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.createRoomButton setTitle:@"进入ZeroTier官网创建房间" forState:UIControlStateNormal];
    [self.createRoomButton addTarget:self action:@selector(createRoomTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.createRoomButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.createRoomButton];

    // Tutorial Label
    self.tutorialLabel = [UILabel new];
    self.tutorialLabel.text = @"创建教程：首先进入后登录账号，登录完成后默认会进入到创建第一个网络的页面，这个时候退出，重新点击此按钮，进入后点击“Create A Network”就会自动创建一个房间，在此页面的下方点击你创建的网络，在“Settings”中把Access Control设置为”Public“，然后把上方的Network ID复制给他人就可以了";
    self.tutorialLabel.numberOfLines = 0;
    self.tutorialLabel.textAlignment = NSTextAlignmentLeft;
    self.tutorialLabel.font = [UIFont systemFontOfSize:12];
    self.tutorialLabel.textColor = [UIColor secondaryLabelColor];
    self.tutorialLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tutorialLabel];

    // Network ID Text Field
    self.networkIdTextField = [UITextField new];
    self.networkIdTextField.placeholder = @"输入16位网络ID (邀请码)";
    self.networkIdTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.networkIdTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.networkIdTextField];

    // Join Room Button
    self.joinRoomButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.joinRoomButton setTitle:@"加入房间" forState:UIControlStateNormal];
    [self.joinRoomButton addTarget:self action:@selector(joinRoomTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.joinRoomButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.joinRoomButton];
    
    // Networks Table View
    self.networksTableView = [UITableView new];
    self.networksTableView.dataSource = self;
    self.networksTableView.delegate = self;
    [self.networksTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"NetworkCell"];
    self.networksTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.networksTableView];
    
    // Info Label
    self.infoLabel = [UILabel new];
    self.infoLabel.text = @"加入网络后，让房主在单人游戏中“对局域网开放”，其他玩家即可在“多人游戏”中看到房间";
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.font = [UIFont systemFontOfSize:12];
    self.infoLabel.textColor = [UIColor secondaryLabelColor];
    self.infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.infoLabel];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [self.createRoomButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:20],
        [self.createRoomButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        [self.tutorialLabel.topAnchor constraintEqualToAnchor:self.createRoomButton.bottomAnchor constant:8],
        [self.tutorialLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.tutorialLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.networkIdTextField.topAnchor constraintEqualToAnchor:self.tutorialLabel.bottomAnchor constant:20],
        [self.networkIdTextField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.networkIdTextField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.joinRoomButton.topAnchor constraintEqualToAnchor:self.networkIdTextField.bottomAnchor constant:10],
        [self.joinRoomButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.joinRoomButton.widthAnchor constraintEqualToConstant:200],
        
        [self.networksTableView.topAnchor constraintEqualToAnchor:self.joinRoomButton.bottomAnchor constant:20],
        [self.networksTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.networksTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.networksTableView.bottomAnchor constraintEqualToAnchor:self.infoLabel.topAnchor constant:-20],
        
        [self.infoLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.infoLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.infoLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];
}

- (void)updateUIForConnectionState {
    BOOL hasJoinedNetworks = self.joinedNetworks.count > 0;

    self.createRoomButton.hidden = hasJoinedNetworks;
    self.tutorialLabel.hidden = hasJoinedNetworks;
    self.networkIdTextField.hidden = hasJoinedNetworks;
    self.joinRoomButton.hidden = hasJoinedNetworks;
}

- (NSString *)imageName {
    return @"network";
}

#pragma mark - Actions

- (void)createRoomTapped:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"https://my.zerotier.com/"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)joinRoomTapped:(UIButton *)sender {
    NSString *networkIDString = self.networkIdTextField.text;
    if (networkIDString.length == 0) {
        [self showAlertWithTitle:@"错误" message:@"请输入网络ID"];
        return;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:networkIDString];
    uint64_t networkID = 0;
    if (![scanner scanHexLongLong:&networkID]) {
        [self showAlertWithTitle:@"错误" message:@"无效的网络ID格式"];
        return;
    }

    [[ZeroTierBridge sharedInstance] joinNetworkWithID:networkID];
}

- (void)leaveRoomTapped:(UIButton *)sender {
    uint64_t networkID = sender.tag;
    [[ZeroTierBridge sharedInstance] leaveNetworkWithID:networkID];
}

#pragma mark - ZeroTierBridgeDelegate

- (void)zeroTierNodeOnlineWithID:(uint64_t)nodeID {
    self.statusLabel.text = [NSString stringWithFormat:@"ZT 节点: %llx | 状态: 在线", nodeID];
}

- (void)zeroTierNodeOffline {
    self.statusLabel.text = @"ZT 节点: 离线";
}

- (void)zeroTierDidJoinNetwork:(uint64_t)networkID {
    NSNumber *key = @(networkID);
    self.joinedNetworks[key] = @{@"networkID": [NSString stringWithFormat:@"%llx", networkID]};
    [self.networksTableView reloadData];
    [self updateUIForConnectionState];
    [self showAlertWithTitle:@"成功" message:[NSString stringWithFormat:@"已加入网络: %llx", networkID]];
}

- (void)zeroTierDidLeaveNetwork:(uint64_t)networkID {
    [self.joinedNetworks removeObjectForKey:@(networkID)];
    [self.networksTableView reloadData];
    [self updateUIForConnectionState];
    [self showAlertWithTitle:@"成功" message:[NSString stringWithFormat:@"已退出网络: %llx", networkID]];
}

- (void)zeroTierFailedToJoinNetwork:(uint64_t)networkID withError:(NSString *)error {
    [self showAlertWithTitle:[NSString stringWithFormat:@"加入 %llx 失败", networkID] message:error];
}

- (void)zeroTierDidReceiveIPAddress:(NSString *)ipAddress forNetworkID:(uint64_t)networkID {
    NSNumber *key = @(networkID);
    NSMutableDictionary *networkInfo = [self.joinedNetworks[key] mutableCopy];
    if (networkInfo) {
        networkInfo[@"ipAddress"] = ipAddress;
        self.joinedNetworks[key] = networkInfo;
        [self.networksTableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.joinedNetworks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NetworkCell" forIndexPath:indexPath];
    
    NSArray *allNetworks = self.joinedNetworks.allValues;
    NSDictionary *networkInfo = allNetworks[indexPath.row];
    
    NSString *networkID = networkInfo[@"networkID"];
    NSString *ipAddress = networkInfo[@"ipAddress"];
    
    if (ipAddress) {
        cell.textLabel.text = [NSString stringWithFormat:@"网络: %@ (IP: %@)", networkID, ipAddress];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"网络: %@ (正在获取IP...)", networkID];
    }
    
    UIButton *leaveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [leaveButton setTitle:@"离开" forState:UIControlStateNormal];
    
    NSScanner *scanner = [NSScanner scannerWithString:networkID];
    uint64_t nwid = 0;
    [scanner scanHexLongLong:&nwid];
    leaveButton.tag = nwid;

    [leaveButton addTarget:self action:@selector(leaveRoomTapped:) forControlEvents:UIControlEventTouchUpInside];
    leaveButton.frame = CGRectMake(0, 0, 60, 30);
    cell.accessoryView = leaveButton;
    
    return cell;
}

#pragma mark - Helpers

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
