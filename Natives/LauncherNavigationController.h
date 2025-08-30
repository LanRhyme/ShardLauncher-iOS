#import <UIKit/UIKit.h>

// This global variable is no longer used here.
// NSMutableArray<NSDictionary *> *localVersionList, *remoteVersionList;

@interface LauncherNavigationController : UINavigationController

@property(nonatomic) UIProgressView *progressViewMain, *progressViewSub;
@property(nonatomic) UILabel* progressText;
@property(nonatomic) UIButton* buttonInstall;

- (void)enterModInstallerWithPath:(NSString *)path hitEnterAfterWindowShown:(BOOL)hitEnter;
- (void)setInteractionEnabled:(BOOL)enable forDownloading:(BOOL)downloading;

@end
