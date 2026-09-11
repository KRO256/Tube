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
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.results.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
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
