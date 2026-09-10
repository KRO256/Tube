#import "AppDelegate.h"
#import "SearchViewController.h"
#import "DownloadManager.h"
#import "SettingsViewController.h"
@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    SearchViewController *s = [[SearchViewController alloc] init];
    s.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Search" image:nil tag:0];
    UIViewController *d = [[DownloadManager shared] downloadsViewController];
    d.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Downloads" image:nil tag:1];
    SettingsViewController *c = [[SettingsViewController alloc] init];
    c.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:nil tag:2];
    UITabBarController *t = [[UITabBarController alloc] init];
    t.viewControllers = @[s, d, c];
    UINavigationController *n0 = [[UINavigationController alloc] initWithRootViewController:s];
    UINavigationController *n1 = [[UINavigationController alloc] initWithRootViewController:d];
    UINavigationController *n2 = [[UINavigationController alloc] initWithRootViewController:c];
    t.viewControllers = @[n0, n1, n2];
    self.window.rootViewController = t;
    [self.window makeKeyAndVisible];
    return YES;
}
@end
