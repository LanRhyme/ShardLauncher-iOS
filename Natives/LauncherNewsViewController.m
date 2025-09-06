#import <WebKit/WebKit.h>
#import "LauncherMenuViewController.h"
#import "LauncherNewsViewController.h"
#import "LauncherPreferences.h"
#import "utils.h"

@interface LauncherNewsViewController()<WKNavigationDelegate>
@end

@implementation LauncherNewsViewController
WKWebView *webView;

- (id)init {
    self = [super init];
    self.title = localize(@"News", nil);
    return self;
}

- (NSString *)imageName {
    return @"MenuNews";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // New URL for the news page
    NSURL *newsURL = [NSURL URLWithString:@"https://shardlauncher-ios.netlify.app/"];
    
    // Use cache policy to allow offline viewing
    NSURLRequest *request = [NSURLRequest requestWithURL:newsURL 
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                         timeoutInterval:60];

    WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:webConfig];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    webView.opaque = NO;
    webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    // Inject viewport meta tag for proper scaling
    NSString *javascript = @"var meta = document.createElement('meta');meta.setAttribute('name', 'viewport');meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *nozoom = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [webView.configuration.userContentController addUserScript:nozoom];
    [webView.scrollView setShowsHorizontalScrollIndicator:NO];
    
    [webView loadRequest:request];
    [self.view addSubview:webView];
    
    // Set constraints to make webView fill the view
    [NSLayoutConstraint activateConstraints:@[[webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
                                              [webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
                                              [webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                                              [webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]]];

    // Warnings (unchanged)
    if(!isJailbroken && getPrefBool(@"warnings.limited_ram_warn") && (roundf(NSProcessInfo.processInfo.physicalMemory / 0x1000000) < 3900)) {
        [self showWarningAlert:@"limited_ram" hasPreference:YES exitWhenCompleted:NO];
    }
    if (@available(iOS 16.0, *)) {
        [self showWarningAlert:@"ios16_jitdead" hasPreference:NO exitWhenCompleted:YES];
    }
}

-(void)showWarningAlert:(NSString *)key hasPreference:(BOOL)isPreferenced exitWhenCompleted:(BOOL)shouldExit {
    UIAlertController *warning = [UIAlertController
                                      alertControllerWithTitle:localize([NSString stringWithFormat:@"login.warn.title.%@", key], nil)
                                      message:localize([NSString stringWithFormat:@"login.warn.message.%@", key], nil)
                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action;
    if(isPreferenced) {
        action = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            setPrefBool([NSString stringWithFormat:@"warnings.%@_warn", key], NO);
        }];
    } else if(shouldExit) {
        action = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
            [UIApplication.sharedApplication performSelector:@selector(suspend)];
            usleep(100*1000);
            exit(0);
        }];
    } else {
        action = [UIAlertAction actionWithTitle:localize(@"OK", nil) style:UIAlertActionStyleCancel handler:nil];
    }
    warning.popoverPresentationController.sourceView = self.view;
    warning.popoverPresentationController.sourceRect = self.view.bounds;
    [warning addAction:action];
    [self presentViewController:warning animated:YES completion:nil];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Prevent horizontal scrolling
    if (scrollView.contentOffset.x > 0)
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
     if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        // Open external links in Safari
        openLink(self, navigationAction.request.URL);
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
