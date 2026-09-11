#import "DownloadManager.h"
#import "YTDLPManager.h"
#import "PlayerViewController.h"
NSString *TubeDownloadsChanged = @"TubeDownloadsChanged";
NSString *TubeDownloadProgress = @"TubeDownloadProgress";
@interface DLCell : UITableViewCell
@property (nonatomic, strong) UIProgressView *bar;
@property (nonatomic, copy) NSString *vid;
@end
@implementation DLCell
- (instancetype)initWithStyle:(UITableViewCellStyle)s reuseIdentifier:(NSString *)rid {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:rid]) {
        self.bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.bar.frame = CGRectMake(15, 40, 290, 4);
        self.bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.bar];
        self.textLabel.font = [UIFont systemFontOfSize:13];
        self.textLabel.numberOfLines = 2;
    }
    return self;
}
@end
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
    NSArray *s = [f sortedArrayUsingSelector:@selector(compare:)];
    return s ? s : @[];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:TubeDownloadsChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prog:) name:TubeDownloadProgress object:nil];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)reload { [self.tableView reloadData]; }
- (void)prog:(NSNotification *)n {
    for (DLCell *c in self.tableView.visibleCells) {
        if ([c isKindOfClass:[DLCell class]] && [c.vid isEqualToString:n.userInfo[@"vid"]])
            [c.bar setProgress:[n.userInfo[@"progress"] floatValue] animated:YES];
    }
}
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; self.title = @"Downloads"; [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 2; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return s == 0 ? @"Downloading" : @"Downloaded"; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s {
    return s == 0 ? [[DownloadManager shared] activeDownloads].count : [self files].count;
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    if (p.section == 0) {
        DLCell *c = [t dequeueReusableCellWithIdentifier:@"q"];
        if (!c) c = [[DLCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"q"];
        NSDictionary *d = [[DownloadManager shared] activeDownloads][p.row];
        c.vid = d[@"vid"];
        c.textLabel.text = d[@"title"];
        [c.bar setProgress:[d[@"progress"] floatValue] animated:NO];
        return c;
    }
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"d"];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"d"];
    c.textLabel.text = [self files][p.row];
    c.textLabel.numberOfLines = 2; c.textLabel.font = [UIFont systemFontOfSize:13];
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    if (p.section == 0) {
        NSDictionary *d = [[DownloadManager shared] activeDownloads][p.row];
        [[DownloadManager shared] cancelDownload:d[@"vid"]];
        return;
    }
    NSString *fp = [[self dir] stringByAppendingPathComponent:[self files][p.row]];
    PlayerViewController *pc = [[PlayerViewController alloc] initWithLocalFile:fp];
    [self.navigationController pushViewController:pc animated:YES];
}
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)s forRowAtIndexPath:(NSIndexPath *)p {
    if (s != UITableViewCellEditingStyleDelete) return;
    if (p.section == 0) {
        NSDictionary *d = [[DownloadManager shared] activeDownloads][p.row];
        [[DownloadManager shared] cancelDownload:d[@"vid"]];
    } else {
        NSString *fp = [[self dir] stringByAppendingPathComponent:[self files][p.row]];
        [[NSFileManager defaultManager] removeItemAtPath:fp error:nil];
        [t deleteRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
@end
@interface DownloadManager () <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary *active;
@end
@implementation DownloadManager
+ (instancetype)shared {
    static DownloadManager *s; static dispatch_once_t t; dispatch_once(&t, ^{ s = [[DownloadManager alloc] init]; });
    return s;
}
- (instancetype)init {
    if (self = [super init]) {
        _active = [NSMutableDictionary dictionary];
        NSURLSessionConfiguration *c = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.local.tube.dl"];
        c.discretionary = NO;
        _session = [NSURLSession sessionWithConfiguration:c delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}
- (UIViewController *)downloadsViewController { return [[DownloadsVC alloc] initWithStyle:UITableViewStylePlain]; }
- (NSArray *)activeDownloads { return [[self.active allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]]; }
- (void)changed { [[NSNotificationCenter defaultCenter] postNotificationName:TubeDownloadsChanged object:nil]; }
- (void)alert:(NSString *)t msg:(NSString *)m {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) return;
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:t message:m delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [a show];
}
- (NSMutableDictionary *)meta {
    NSDictionary *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"TubeDLMeta"];
    return d ? [d mutableCopy] : [NSMutableDictionary dictionary];
}
- (void)saveMeta:(NSString *)vid title:(NSString *)title dest:(NSString *)dest {
    NSMutableDictionary *m = [self meta];
    m[vid] = @{@"title": title, @"dest": dest};
    [[NSUserDefaults standardUserDefaults] setObject:m forKey:@"TubeDLMeta"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)dropMeta:(NSString *)vid {
    NSMutableDictionary *m = [self meta];
    [m removeObjectForKey:vid];
    [[NSUserDefaults standardUserDefaults] setObject:m forKey:@"TubeDLMeta"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)downloadVideo:(NSDictionary *)video audioOnly:(BOOL)audio {
    NSString *vid = video[@"id"];
    NSString *raw = video[@"title"] ? video[@"title"] : vid;
    NSString *safe = [raw stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    if (safe.length > 80) safe = [safe substringToIndex:80];
    NSString *title = [NSString stringWithFormat:@"%@-%@", safe, vid];
    [[YTDLPManager shared] streamURLForVideoID:vid audioOnly:audio completion:^(NSString *u, NSString *e) {
        if (!u) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Error" message:e delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show]; return;
        }
        NSString *ext = audio ? @"m4a" : @"mp4";
        NSString *dir = @"/var/mobile/Media/Tube";
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *dest = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", title, ext]];
        NSURLSessionDownloadTask *task = [self.session downloadTaskWithURL:[NSURL URLWithString:u]];
        task.taskDescription = vid;
        self.active[vid] = [@{@"vid": vid, @"title": title, @"dest": dest, @"task": task, @"progress": @0} mutableCopy];
        [self saveMeta:vid title:title dest:dest];
        [task resume];
        [self changed];
        [self alert:@"Download started" msg:title];
    }];
}
- (void)cancelDownload:(NSString *)vid {
    NSMutableDictionary *d = self.active[vid];
    if (!d) return;
    [d[@"task"] cancel];
    [self.active removeObjectForKey:vid];
    [self dropMeta:vid];
    [self changed];
}
- (void)URLSession:(NSURLSession *)s downloadTask:(NSURLSessionDownloadTask *)t didWriteData:(int64_t)b totalBytesWritten:(int64_t)w totalBytesExpectedToWrite:(int64_t)x {
    NSMutableDictionary *d = self.active[t.taskDescription];
    if (!d) return;
    float p = x > 0 ? (float)w / (float)x : 0;
    d[@"progress"] = @(p);
    [[NSNotificationCenter defaultCenter] postNotificationName:TubeDownloadProgress object:nil userInfo:@{@"vid": t.taskDescription, @"progress": @(p)}];
}
- (void)URLSession:(NSURLSession *)s downloadTask:(NSURLSessionDownloadTask *)t didFinishDownloadingToURL:(NSURL *)loc {
    NSMutableDictionary *d = self.active[t.taskDescription];
    NSString *dest = d ? d[@"dest"] : [self meta][t.taskDescription][@"dest"];
    NSString *title = d ? d[@"title"] : [self meta][t.taskDescription][@"title"];
    [self.active removeObjectForKey:t.taskDescription];
    [self dropMeta:t.taskDescription];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *msg = nil;
    if (!dest) msg = @"unknown destination";
    else if (!loc || ![fm fileExistsAtPath:loc.path]) msg = @"temp file missing";
    else {
        [fm removeItemAtPath:dest error:nil];
        NSError *mv = nil;
        if (![fm moveItemAtPath:loc.path toPath:dest error:&mv]) {
            if ([fm copyItemAtPath:loc.path toPath:dest error:&mv]) {
                [fm removeItemAtPath:loc.path error:nil];
                mv = nil;
            }
        }
        msg = mv ? mv.localizedDescription : nil;
    }
    [self changed];
    NSString *done = msg ? msg : [@"Saved: " stringByAppendingString:(title ? title : dest)];
    [self alert:@"Download" msg:done];
}
- (void)URLSession:(NSURLSession *)s task:(NSURLSessionTask *)t didCompleteWithError:(NSError *)e {
    if (!e) return;
    NSMutableDictionary *d = self.active[t.taskDescription];
    if (!d) return;
    [self.active removeObjectForKey:t.taskDescription];
    [self dropMeta:t.taskDescription];
    [self changed];
    [self alert:@"Download" msg:e.localizedDescription];
}
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)s {
    if (self.backgroundCompletion) {
        void (^h)(void) = self.backgroundCompletion;
        self.backgroundCompletion = nil;
        h();
    }
}
@end
