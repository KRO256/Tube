#import "DownloadManager.h"
#import "YTDLPManager.h"
#import "PlayerViewController.h"
@interface DownloadsVC : UITableViewController
@end
@implementation DownloadsVC
- (NSString *)dir {
    NSString *d = @"/var/mobile/Media/Tube";
    [[NSFileManager defaultManager] createDirectoryAtPath:d withIntermediateDirectories:YES attributes:nil error:nil];
    return d;
}
- (NSArray *)files {
    NSArray *f = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self dir] error:nil];
    return [f sortedArrayUsingSelector:@selector(compare:)] ?: @[];
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; self.title = @"Downloads"; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return [self files].count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"d"];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"d"];
    c.textLabel.text = [self files][p.row];
    c.textLabel.numberOfLines = 2; c.textLabel.font = [UIFont systemFontOfSize:13];
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    NSString *fp = [[self dir] stringByAppendingPathComponent:[self files][p.row]];
    PlayerViewController *pc = [[PlayerViewController alloc] initWithLocalFile:fp];
    [self.navigationController pushViewController:pc animated:YES];
}
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)s forRowAtIndexPath:(NSIndexPath *)p {
    if (s == UITableViewCellEditingStyleDelete) {
        NSString *fp = [[self dir] stringByAppendingPathComponent:[self files][p.row]];
        [[NSFileManager defaultManager] removeItemAtPath:fp error:nil];
        [t deleteRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
@end
@implementation DownloadManager
+ (instancetype)shared {
    static DownloadManager *s; static dispatch_once_t t; dispatch_once(&t, ^{ s = [[DownloadManager alloc] init]; });
    return s;
}
- (UIViewController *)downloadsViewController { return [[DownloadsVC alloc] initWithStyle:UITableViewStylePlain]; }
- (void)downloadVideo:(NSDictionary *)video audioOnly:(BOOL)audio {
    NSString *vid = video[@"id"];
    NSString *rawTitle = video[@"title"] ? video[@"title"] : vid;
    NSString *title = [rawTitle stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    [[YTDLPManager shared] streamURLForVideoID:vid audioOnly:audio completion:^(NSString *u, NSString *e) {
        if (!u) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Error" message:e delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show]; return;
        }
        NSURL *url = [NSURL URLWithString:u];
        NSString *ext = audio ? @"m4a" : @"mp4";
        NSString *dir = @"/var/mobile/Media/Tube";
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *dest = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", title, ext]];
        NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *tmp, NSURLResponse *r, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (err) {
                    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"DL failed" message:err.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [a show]; return;
                }
                [[NSFileManager defaultManager] removeItemAtPath:dest error:nil];
                NSError *mv;
                [[NSFileManager defaultManager] moveItemAtPath:tmp.path toPath:dest error:&mv];
                NSString *msg = mv ? mv.localizedDescription : [@"Saved: " stringByAppendingString:dest];
                UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Download" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [a show];
            });
        }];
        [task resume];
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Download started" message:title delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [a show];
    }];
}
@end
