#import "PlaylistViewController.h"
#import "PlaylistManager.h"
#import "PlaybackManager.h"
@interface PlaylistDetailVC : UITableViewController
- (instancetype)initWithIndex:(NSInteger)idx;
@end
@implementation PlaylistDetailVC {
    NSInteger _idx;
}
- (instancetype)initWithIndex:(NSInteger)idx {
    if (self = [super initWithStyle:UITableViewStylePlain]) _idx = idx;
    return self;
}
- (NSDictionary *)pl {
    NSArray *p = [[PlaylistManager shared] playlists];
    return (_idx >= 0 && _idx < p.count) ? p[_idx] : nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self pl][@"name"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rl) name:TubePlaylistsChanged object:nil];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)rl {
    self.title = [self pl][@"name"];
    [self.tableView reloadData];
}
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return [[self pl][@"items"] count]; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"i"];
    if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"i"]; c.textLabel.numberOfLines = 2; c.textLabel.font = [UIFont systemFontOfSize:13]; }
    c.textLabel.text = [self pl][@"items"][p.row][@"title"];
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    [[PlaybackManager shared] playItems:[self pl][@"items"] startingAt:p.row];
}
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)s forRowAtIndexPath:(NSIndexPath *)p {
    if (s == UITableViewCellEditingStyleDelete) {
        [[PlaylistManager shared] removeItemAt:p.row fromPlaylist:_idx];
        [t deleteRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
@end
@implementation PlaylistViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Playlists";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rl) name:TubePlaybackChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rl) name:TubePlaylistsChanged object:nil];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)rl { [self.tableView reloadData]; }
- (void)viewWillAppear:(BOOL)a { [super viewWillAppear:a]; [self.tableView reloadData]; }
- (void)add {
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"New Playlist" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    [a show];
}
- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i {
    if (i == 1) [[PlaylistManager shared] createPlaylist:[a textFieldAtIndex:0].text];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 2; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return s == 0 ? @"Up Next" : @"Playlists"; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s {
    if (s == 0) {
        NSInteger n = [PlaybackManager shared].queue.count;
        return n ? n + 1 : 0;
    }
    return [[PlaylistManager shared] playlists].count;
}
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    if (p.section == 1) {
        UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"p"];
        if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"p"]; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; }
        NSDictionary *pl = [[PlaylistManager shared] playlists][p.row];
        c.textLabel.text = pl[@"name"];
        c.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[pl[@"items"] count]];
        return c;
    }
    PlaybackManager *m = [PlaybackManager shared];
    if (p.row >= m.queue.count) {
        UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"c"];
        if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"]; c.textLabel.textAlignment = NSTextAlignmentCenter; c.textLabel.textColor = [UIColor redColor]; }
        c.textLabel.text = @"Clear Up Next";
        return c;
    }
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"q"];
    if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"q"]; c.textLabel.numberOfLines = 2; c.textLabel.font = [UIFont systemFontOfSize:13]; }
    c.textLabel.text = m.queue[p.row][@"title"];
    c.accessoryType = (p.row == m.queueIndex) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return c;
}
- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)p {
    return !(p.section == 0 && p.row >= [PlaybackManager shared].queue.count);
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    if (p.section == 1) {
        [self.navigationController pushViewController:[[PlaylistDetailVC alloc] initWithIndex:p.row] animated:YES];
        return;
    }
    PlaybackManager *m = [PlaybackManager shared];
    if (p.row >= m.queue.count) [m clearUpcoming];
    else [m playQueueAt:p.row];
}
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)s forRowAtIndexPath:(NSIndexPath *)p {
    if (s != UITableViewCellEditingStyleDelete) return;
    if (p.section == 0) {
        [[PlaybackManager shared] removeQueueAt:p.row];
        [t deleteRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [[PlaylistManager shared] deletePlaylistAt:p.row];
        [t deleteRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
@end
