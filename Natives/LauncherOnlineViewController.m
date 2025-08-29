#import "LauncherOnlineViewController.h"
#import "ZeroTier/ZeroTierBridge.h"

@interface LauncherOnlineViewController () <ZeroTierBridgeDelegate, UITableViewDataSource, UITableViewDelegate>

// UI Elements
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *createRoomButton;
@property (nonatomic, strong) UITextField *networkIdTextField;
@property (nonatomic, strong) UIButton *joinRoomButton;
@property (nonatomic, strong) UITableView *networksTableView;
@property (nonatomic, strong) UILabel *infoLabel;

// Data
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *joinedNetworks;

@end

@implementation LauncherOnlineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"联机 (ZeroTier)";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.joinedNetworks = [NSMutableArray new];

    [self setupUI];
    
    // Start ZeroTier Node
    [ZeroTierBridge sharedInstance].delegate = self;
    [[ZeroTierBridge sharedInstance] startNode];
}

- (void)setupUI {
    // Status Label
    self.statusLabel = [UILabel new];
    self.statusLabel.text = [NSString stringWithFormat:@"ZT 节点 ID: %@ | 状态: 正在初始化...", [[ZeroTierBridge sharedInstance] nodeID]];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // Create Room Button
    self.createRoomButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.createRoomButton setTitle:@"创建房间" forState:UIControlStateNormal];
    [self.createRoomButton addTarget:self action:@selector(createRoomTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.createRoomButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.createRoomButton];

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
        [self.createRoomButton.widthAnchor constraintEqualToConstant:200],

        [self.networkIdTextField.topAnchor constraintEqualToAnchor:self.createRoomButton.bottomAnchor constant:20],
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

- (NSString *)imageName {
    return @"network";
}

#pragma mark - Actions

- (void)createRoomTapped:(UIButton *)sender {
    self.statusLabel.text = [NSString stringWithFormat:@"ZT 节点 ID: %@ | 状态: 正在创建网络...", [[ZeroTierBridge sharedInstance] nodeID]];
    [[ZeroTierBridge sharedInstance] createAndJoinPrivateNetwork];
}

- (void)joinRoomTapped:(UIButton *)sender {
    NSString *networkID = self.networkIdTextField.text;
    if (networkID.length == 0) {
        [self showAlertWithTitle:@"错误" message:@"请输入网络ID"];
        return;
    }
    self.statusLabel.text = [NSString stringWithFormat:@"ZT 节点 ID: %@ | 状态: 正在加入 %@...", [[ZeroTierBridge sharedInstance] nodeID], networkID];
    [[ZeroTierBridge sharedInstance] joinNetworkWithID:networkID];
}

- (void)leaveRoomTapped:(UIButton *)sender {
    NSString *networkID = self.joinedNetworks[sender.tag][@"networkID"];
    [[ZeroTierBridge sharedInstance] leaveNetworkWithID:networkID];
}

#pragma mark - ZeroTierBridgeDelegate

- (void)zeroTierStatusDidChange:(NSString *)status {
    self.statusLabel.text = [NSString stringWithFormat:@"ZT 节点 ID: %@ | 状态: %@", [[ZeroTierBridge sharedInstance] nodeID], status];
}

- (void)zeroTierDidJoinNetwork:(NSString *)networkID withIPAddress:(NSString *)ipAddress {
    self.statusLabel.text = [NSString stringWithFormat:@"ZT 节点 ID: %@ | 状态: Online", [[ZeroTierBridge sharedInstance] nodeID]];
    self.networkIdTextField.text = @"";
    
    NSDictionary *networkInfo = @{@"networkID": networkID, @"ipAddress": ipAddress};
    [self.joinedNetworks addObject:networkInfo];
    [self.networksTableView reloadData];
}

- (void)zeroTierDidLeaveNetwork:(NSString *)networkID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"networkID != %@", networkID];
    [self.joinedNetworks filterUsingPredicate:predicate];
    [self.networksTableView reloadData];
}

- (void)zeroTierDidFailWithError:(NSString *)error {
    [self showAlertWithTitle:@"ZeroTier 错误" message:error];
    self.statusLabel.text = [NSString stringWithFormat:@"ZT 节点 ID: %@ | 状态: Error", [[ZeroTierBridge sharedInstance] nodeID]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.joinedNetworks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NetworkCell" forIndexPath:indexPath];
    NSDictionary *networkInfo = self.joinedNetworks[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"网络: %@ (IP: %@)", networkInfo[@"networkID"], networkInfo[@"ipAddress"]];
    
    UIButton *leaveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [leaveButton setTitle:@"离开" forState:UIControlStateNormal];
    leaveButton.tag = indexPath.row;
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
