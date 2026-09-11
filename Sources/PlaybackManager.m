#import "PlaybackManager.h"
#import <MediaPlayer/MediaPlayer.h>
NSString *TubePlaybackChanged = @"TubePlaybackChanged";
@interface PlaybackManager ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, copy) NSString *currentTitle;
@property (nonatomic) BOOL isVideo;
@end
@implementation PlaybackManager
+ (instancetype)shared {
    static PlaybackManager *s; static dispatch_once_t t; dispatch_once(&t, ^{ s = [[PlaybackManager alloc] init]; });
    return s;
}
- (void)playURL:(NSURL *)url title:(NSString *)title video:(BOOL)video {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (!self.player) self.player = [[AVPlayer alloc] init];
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:url]];
    self.currentTitle = title.length ? title : @"Tube";
    self.isVideo = video;
    [self.player play];
    [self pushInfo:YES];
}
- (void)playLocalFile:(NSString *)path {
    [self playURL:[NSURL fileURLWithPath:path] title:[path lastPathComponent] video:![[path pathExtension] isEqualToString:@"m4a"]];
}
- (void)toggle {
    if ([self isPlaying]) [self.player pause];
    else [self.player play];
    [self pushInfo:[self isPlaying]];
}
- (BOOL)isPlaying { return self.player && self.player.rate != 0; }
- (void)handleRemoteEvent:(UIEvent *)e {
    if (e.type != UIEventTypeRemoteControl) return;
    if (e.subtype == UIEventSubtypeRemoteControlPlay) { [self.player play]; [self pushInfo:YES]; }
    else if (e.subtype == UIEventSubtypeRemoteControlPause) { [self.player pause]; [self pushInfo:NO]; }
    else if (e.subtype == UIEventSubtypeRemoteControlTogglePlayPause) [self toggle];
}
- (void)pushInfo:(BOOL)playing {
    if (self.currentTitle) {
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{
            MPMediaItemPropertyTitle: self.currentTitle,
            MPNowPlayingInfoPropertyPlaybackRate: playing ? @1 : @0
        }];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TubePlaybackChanged object:nil];
}
@end
