#import "PlayerViewController.h"
#import "YTDLPManager.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
@interface PlayerViewController ()
@property (nonatomic, strong) NSDictionary *video;
@property (nonatomic) BOOL audioOnly;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, strong) AVPlayer *player;
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
- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    self.view.backgroundColor = [UIColor blackColor];
    self.title = self.video[@"title"] ?: [self.localPath lastPathComponent];
    self.spin = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spin.center = self.view.center; [self.spin startAnimating];
    [self.view addSubview:self.spin];
    if (self.localPath) { [self playURL:[NSURL fileURLWithPath:self.localPath]]; return; }
    NSString *vid = self.video[@"id"] ?: self.video[@"url"];
    [[YTDLPManager shared] streamURLForVideoID:vid audioOnly:self.audioOnly completion:^(NSString *u, NSString *e) {
        [self.spin stopAnimating];
        if (!u) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Error" message:e delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show]; return;
        }
        [self playURL:[NSURL URLWithString:u]];
    }];
}
- (BOOL)canBecomeFirstResponder { return YES; }
- (void)nowPlaying:(BOOL)playing {
    NSString *t = self.video ? self.video[@"title"] : [self.localPath lastPathComponent];
    if (!t) t = @"Tube";
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{
        MPMediaItemPropertyTitle: t,
        MPNowPlayingInfoPropertyPlaybackRate: playing ? @1 : @0
    }];
}
- (void)remoteControlReceivedWithEvent:(UIEvent *)e {
    if (e.type != UIEventTypeRemoteControl) return;
    switch (e.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [self.player play]; [self.toggle setTitle:@"Pause" forState:UIControlStateNormal]; [self nowPlaying:YES]; break;
        case UIEventSubtypeRemoteControlPause:
            [self.player pause]; [self.toggle setTitle:@"Play" forState:UIControlStateNormal]; [self nowPlaying:NO]; break;
        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self togglePlay]; break;
        default: break;
    }
}
- (void)playURL:(NSURL *)url {
    self.player = [AVPlayer playerWithURL:url];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (self.audioOnly || self.localPath) {
        self.toggle = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.toggle setTitle:@"Pause" forState:UIControlStateNormal];
        self.toggle.tintColor = [UIColor whiteColor];
        self.toggle.frame = CGRectMake(0, 0, 200, 44);
        self.toggle.center = self.view.center;
        [self.toggle addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.toggle];
        [self.player play];
    } else {
        self.vc = [[AVPlayerViewController alloc] init];
        self.vc.player = self.player;
        self.vc.view.frame = self.view.bounds;
        self.vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addChildViewController:self.vc];
        [self.view addSubview:self.vc.view];
        [self.vc didMoveToParentViewController:self];
        [self.player play];
    }
    [self nowPlaying:YES];
}
- (void)togglePlay {
    if (self.player.rate == 0) { [self.player play]; [self.toggle setTitle:@"Pause" forState:UIControlStateNormal]; [self nowPlaying:YES]; }
    else { [self.player pause]; [self.toggle setTitle:@"Play" forState:UIControlStateNormal]; [self nowPlaying:NO]; }
}
- (void)viewDidDisappear:(BOOL)a {
    [super viewDidDisappear:a];
    [self.player pause];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}
@end
