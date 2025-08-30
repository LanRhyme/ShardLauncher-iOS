#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "authenticator/BaseAuthenticator.h"
#import "AFNetworking.h"
#import "ALTServerConnection.h"
#import "CustomControlsViewController.h"
#import "DownloadProgressViewController.h"
#import "JavaGUIViewController.h"
#import "LauncherMenuViewController.h"
#import "LauncherNavigationController.h"
#import "LauncherPreferences.h"
#import "MinecraftResourceDownloadTask.h"
#import "MinecraftResourceUtils.h"
#import "PLProfiles.h"
#import "UIKit+AFNetworking.h"
#import "UIKit+hook.h"
#import "ios_uikit_bridge.h"
#import "utils.h"

#include <sys/time.h>

@interface LauncherNavigationController () <UIDocumentPickerDelegate, UIPopoverPresentationControllerDelegate>
@property(nonatomic) MinecraftResourceDownloadTask* task;
@property(nonatomic) DownloadProgressViewController* progressVC;
@end

@implementation LauncherNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(setNeedsUpdateOfScreenEdgesDeferringSystemGestures)]) {
        [self setNeedsUpdateOfScreenEdgesDeferringSystemGestures];
    }

    // The toolbar and all its contents have been moved to the right panel.
    self.toolbarHidden = YES;

    // The notification for modpack installation is still relevant.
    [NSNotificationCenter.defaultCenter addObserver:self
        selector:@selector(receiveNotification:)
        name:@"InstallModpack"
        object:nil];

    // Token refresh logic is still needed for the account.
    if ([BaseAuthenticator.current isKindOfClass:MicrosoftAuthenticator.class]) {
        id callback = ^(NSString* status, BOOL success) {
            if (!success && status != nil) {
                showDialog(localize(@"Error", nil), status);
            }
        };
        [BaseAuthenticator.current refreshTokenWithCallback:callback];
    }
}

#pragma mark - Options
- (void)enterCustomControls {
    CustomControlsViewController *vc = [[CustomControlsViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.setDefaultCtrl = ^(NSString *name){
        setPrefObject(@"control.default_ctrl", name);
    };
    vc.getDefaultCtrl = ^{
        return getPrefObject(@"control.default_ctrl");
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)enterModInstaller {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[[UTType typeWithMIMEType:@"application/java-archive"]]
        asCopy:YES];
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)enterModInstallerWithPath:(NSString *)path hitEnterAfterWindowShown:(BOOL)hitEnter {
    JavaGUIViewController *vc = [[JavaGUIViewController alloc] init];
    vc.filepath = path;
    vc.hitEnterAfterWindowShown = hitEnter;
    if (!vc.requiredJavaVersion) {
        return;
    }
    [self invokeAfterJITEnabled:^{
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        NSLog(@"[ModInstaller] launching %@", vc.filepath);
        [self presentViewController:vc animated:YES completion:nil];
    }];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [self enterModInstallerWithPath:url.path hitEnterAfterWindowShown:NO];
}

- (void)setInteractionEnabled:(BOOL)enabled forDownloading:(BOOL)downloading {
    UIApplication.sharedApplication.idleTimerDisabled = !enabled;
}

- (void)receiveNotification:(NSNotification *)notification {
    if (![notification.name isEqualToString:@"InstallModpack"]) {
        return;
    }

    self.task = [MinecraftResourceDownloadTask new];
    NSDictionary *userInfo = notification.userInfo;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __weak LauncherNavigationController *weakSelf = self;
        self.task.handleError = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.task = nil;
                weakSelf.progressVC = nil;
            });
        };
        [self.task downloadModpackFromAPI:notification.object detail:userInfo[@"detail"] atIndex:[userInfo[@"index"] unsignedLongValue]];
    });
}

- (void)invokeAfterJITEnabled:(void(^)(void))handler {
    BOOL hasTrollStoreJIT = getEntitlementValue(@"com.apple.private.local.sandboxed-jit");

    if (isJITEnabled(false)) {
        [ALTServerManager.sharedManager stopDiscovering];
        handler();
        return;
    } else if (hasTrollStoreJIT) {
        NSURL *jitURL = [NSURL URLWithString:[NSString stringWithFormat:@"apple-magnifier://enable-jit?bundle-id=%@", NSBundle.mainBundle.bundleIdentifier]];
        [UIApplication.sharedApplication openURL:jitURL options:@{} completionHandler:nil];
    } else if (getPrefBool(@"debug.debug_skip_wait_jit")) {
        NSLog(@"Debug option skipped waiting for JIT. Java might not work.");
        handler();
        return;
    }

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:localize(@"launcher.wait_jit.title", nil)
        message:hasTrollStoreJIT ? localize(@"launcher.wait_jit_trollstore.message", nil) : localize(@"launcher.wait_jit.message", nil)
        preferredStyle:UIAlertControllerStyleAlert];

    [self presentViewController:alert animated:YES completion:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!isJITEnabled(false)) {
            usleep(1000*200);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:handler];
        });
    });
}

#pragma mark - UIPopoverPresentationControllerDelegate
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

#pragma mark - View controller UI mode

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

@end
