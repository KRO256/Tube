#import "SearchViewController.h"
#import "YTDLPManager.h"
#import "PlayerViewController.h"
#import "DownloadManager.h"
#import "PlaybackManager.h"
#import "PlaylistManager.h"
@interface SearchViewController ()
@property (nonatomic, strong) UISearchBar *bar;
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) UIActivityIndicatorView *spin;
@property (nonatomic, strong) NSArray *results;
@property (nonatomic, strong) NSArray *suggests;
@property (nonatomic, strong) NSURLSessionDataTask *suggestTask;
@end
@implementation SearchViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Tube";
    self.view.backgroundColor = [UIColor whiteColor];
    self.bar = [[UISearchBar alloc] init];
    self.bar.delegate = self;
    self.bar.placeholder = @"Search YouTube";
    self.bar.showsCancelButton = YES;
    self.navigationItem.titleView = self.bar;
    self.table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.table.dataSource = self; self.table.delegate = self;
    [self.view addSubview:self.table];
    self.spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spin.center = self.view.center;
    self.spin.hidesWhenStopped = YES;
    [self.view addSubview:self.spin];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)bar {
    [bar resignFirstResponder];
    if (!bar.text.length) return;
    self.suggests = @[];
    [self.suggestTask cancel];
    [self.spin startAnimating];
    [[YTDLPManager shared] search:bar.text max:15 completion:^(NSArray *r, NSString *e) {
        [self.spin stopAnimating];
        if (e) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Error" message:e delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show]; return;
        }
        self.results = r;
        [self.table reloadData];
    }];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)bar { [bar resignFirstResponder]; }
- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)text {
    [self.suggestTask cancel];
    if (!text.length) { self.suggests = @[]; [self.table reloadData]; return; }
    NSString *q = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *u = [NSURL URLWithString:[@"https://suggestqueries.google.com/complete/search?client=youtube&ds=yt&q=" stringByAppendingString:q]];
    __weak SearchViewController *w = self;
    self.suggestTask = [[NSURLSession sharedSession] dataTaskWithURL:u completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e || !d) return;
        NSArray *j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        if (!j) {
            NSString *raw = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
            NSRange a = [raw rangeOfString:@"("];
            NSRange b = [raw rangeOfString:@")" options:NSBackwardsSearch];
            if (a.location != NSNotFound && b.location != NSNotFound && b.location > a.location) {
                NSString *inner = [raw substringWithRange:NSMakeRange(a.location + 1, b.location - a.location - 1)];
                j = [NSJSONSerialization JSONObjectWithData:[inner dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            }
        }
        NSMutableArray *out = [NSMutableArray array];
        if ([j isKindOfClass:[NSArray class]] && j.count > 1 && [j[1] isKindOfClass:[NSArray class]]) {
            for (id s in j[1]) {
                NSString *t = [s isKindOfClass:[NSString class]] ? s : ([s isKindOfClass:[NSArray class]] && [s count] ? s[0] : nil);
                if ([t isKindOfClass:[NSString class]] && t.length) [out addObject:t];
                if (out.count >= 8) break;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            w.suggests = out;
            if (!w.results.count) [w.table reloadData];
        });
    }];
    [self.suggestTask resume];
}
- (BOOL)showingResults { return self.results.count > 0; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s {
    return [self showingResults] ? self.results.count : self.suggests.count;
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    if (![self showingResults]) {
        UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"s"];
        if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"s"];
        c.textLabel.text = self.suggests[p.row];
        c.textLabel.font = [UIFont systemFontOfSize:14];
        c.textLabel.textColor = [UIColor grayColor];
        return c;
    }
    static NSString *ID = @"c";
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:ID];
    if (!c) c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    NSDictionary *v = self.results[p.row];
    c.textLabel.text = v[@"title"] ?: v[@"id"];
    NSString *dur = v[@"duration"] ? [NSString stringWithFormat:@"%@s", v[@"duration"]] : @"";
    c.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", v[@"uploader"] ?: @"", dur];
    c.textLabel.numberOfLines = 2;
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    if (![self showingResults]) {
        self.bar.text = self.suggests[p.row];
        [self searchBarSearchButtonClicked:self.bar];
        return;
    }
    NSDictionary *v = self.results[p.row];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:v[@"title"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [ac addAction:[UIAlertAction actionWithTitle:@"Video Play" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        PlayerViewController *pc = [[PlayerViewController alloc] initWithVideo:v audioOnly:NO];
        [self.navigationController pushViewController:pc animated:YES];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Audio Play" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        PlayerViewController *pc = [[PlayerViewController alloc] initWithVideo:v audioOnly:YES];
        [self.navigationController pushViewController:pc animated:YES];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [[DownloadManager shared] downloadVideo:v audioOnly:NO];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Download (audio)" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [[DownloadManager shared] downloadVideo:v audioOnly:YES];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Play Next" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [[PlaybackManager shared] playItemNext:[PlaybackManager streamItemWithID:v[@"id"] title:v[@"title"] audioOnly:NO]];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Add to Queue" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [[PlaybackManager shared] enqueueItem:[PlaybackManager streamItemWithID:v[@"id"] title:v[@"title"] audioOnly:NO]];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Add to Playlist..." style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self pickPlaylist:v];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}
- (void)pickPlaylist:(NSDictionary *)v {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Add to Playlist" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *pls = [[PlaylistManager shared] playlists];
    NSInteger i = 0;
    for (NSDictionary *pl in pls) {
        NSInteger idx = i++;
        [ac addAction:[UIAlertAction actionWithTitle:pl[@"name"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[PlaylistManager shared] addItem:[PlaybackManager streamItemWithID:v[@"id"] title:v[@"title"] audioOnly:NO] toPlaylist:idx];
        }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}
@end
