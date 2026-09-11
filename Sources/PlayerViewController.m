#import "PlayerViewController.h"
#import "YTDLPManager.h"
#import "PlaybackManager.h"
#import <AVKit/AVKit.h>
@interface PlayerViewController ()
@property (nonatomic, strong) NSDictionary *video;
@property (nonatomic) BOOL audioOnly;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic) BOOL shared;
@property (nonatomic, strong) AVPlayerViewController *vc;
@property (nonatomic, strong) UIButton *toggle;
@property (nonatomic, strong) UIActivityIndicatorView *spin;
@end
@implementation PlayerViewController
- (instancetype)initWithVideo:(NSDictionary *)v audioOnly:(BOOL)a {
    if (self = [super init]) { _video = v; _audioOnly = a; }
    return self;
}
- (instancetype)initWithLocalFile:(NSString *)p {
    if (self = [super init]) { _localPath = p; }
    return self;
}
- (instancetype)initWithShared {
    if (self = [super init]) { _shared = YES; }
    return self;
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncUI) name:TubePlaybackChanged object:nil];
    if (self.shared) { [self buildPlayerUI]; [self syncUI]; return; }
    self.title = self.video ? self.video[@"title"] : [self.localPath lastPathComponent];
    self.spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spin.center = self.view.center; [self.spin startAnimating];
    [self.view addSubview:self.spin];
    if (self.localPath) {
        [[PlaybackManager shared] playLocalFile:self.localPath];
        [self.spin stopAnimating]; [self buildPlayerUI]; [self syncUI]; return;
    }
    NSString *vid = self.video[@"id"] ? self.video[@"id"] : self.video[@"url"];
    NSString *t = self.video[@"title"] ? self.video[@"title"] : vid;
    [[YTDLPManager shared] streamURLForVideoID:vid audioOnly:self.audioOnly completion:^(NSString *u, NSString *e) {
        [self.spin stopAnimating];
        if (!u) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Error" message:e delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show]; return;
        }
        [[PlaybackManager shared] playURL:[NSURL URLWithString:u] title:t video:!self.audioOnly];
        [self buildPlayerUI]; [self syncUI];
    }];
}
- (void)buildPlayerUI {
    PlaybackManager *m = [PlaybackManager shared];
    if (self.vc) { [self.vc willMoveToParentViewController:nil]; [self.vc.view removeFromSuperview]; [self.vc removeFromParentViewController]; self.vc = nil; }
    if (self.toggle) { [self.toggle removeFromSuperview]; self.toggle = nil; }
    if (m.isVideo && m.player.currentItem) {
        self.vc = [[AVPlayerViewController alloc] init];
        self.vc.player = m.player;
        self.vc.view.frame = self.view.bounds;
        self.vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addChildViewController:self.vc];
        [self.view addSubview:self.vc.view];
        [self.vc didMoveToParentViewController:self];
    } else {
        self.toggle = [UIButton buttonWithType:UIButtonTypeSystem];
        self.toggle.tintColor = [UIColor whiteColor];
        self.toggle.frame = CGRectMake(0, 0, 200, 44);
        self.toggle.center = self.view.center;
        self.toggle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.toggle addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.toggle];
    }
}
- (void)syncUI {
    PlaybackManager *m = [PlaybackManager shared];
    self.title = m.currentTitle;
    [self.toggle setTitle:[m isPlaying] ? @"Pause" : @"Play" forState:UIControlStateNormal];
}
- (void)togglePlay { [[PlaybackManager shared] toggle]; }
@end
