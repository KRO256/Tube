#import "AppDelegate.h"
#import "SearchViewController.h"
#import "DownloadManager.h"
#import "SettingsViewController.h"
#import "PlayerViewController.h"
#import "PlaybackManager.h"
#import "MiniPlayerBar.h"
@interface AppDelegate ()
@property (nonatomic, strong) UITabBarController *tabs;
@property (nonatomic, strong) MiniPlayerBar *bar;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    SearchViewController *s = [[SearchViewController alloc] init];
    UIViewController *d = [[DownloadManager shared] downloadsViewController];
    SettingsViewController *c = [[SettingsViewController alloc] init];
    UINavigationController *n0 = [[UINavigationController alloc] initWithRootViewController:s];
    UINavigationController *n1 = [[UINavigationController alloc] initWithRootViewController:d];
    UINavigationController *n2 = [[UINavigationController alloc] initWithRootViewController:c];
    n0.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Search" image:nil tag:0];
    n1.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Downloads" image:nil tag:1];
    n2.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:nil tag:2];
    self.tabs = [[UITabBarController alloc] init];
    self.tabs.viewControllers = @[n0, n1, n2];
    self.window.rootViewController = self.tabs;
    [self.window makeKeyAndVisible];
    CGRect f = self.tabs.view.bounds;
    self.bar = [[MiniPlayerBar alloc] initWithFrame:CGRectMake(0, f.size.height - 49 - 48, f.size.width, 48)];
    __weak AppDelegate *w = self;
    self.bar.onTap = ^{
        PlayerViewController *pc = [[PlayerViewController alloc] initWithShared];
        [(UINavigationController *)w.tabs.selectedViewController pushViewController:pc animated:YES];
    };
    [self.tabs.view addSubview:self.bar];
    return YES;
}
- (void)remoteControlReceivedWithEvent:(UIEvent *)e {
    [[PlaybackManager shared] handleRemoteEvent:e];
}
- (void)application:(UIApplication *)app handleEventsForBackgroundURLSession:(NSString *)ident completionHandler:(void (^)(void))h {
    [DownloadManager shared].backgroundCompletion = h;
}
@end
