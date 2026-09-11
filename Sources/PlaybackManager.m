#import "PlaybackManager.h"
#import "YTDLPManager.h"
#import <MediaPlayer/MediaPlayer.h>
NSString *TubePlaybackChanged = @"TubePlaybackChanged";
@interface PlaybackManager ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, copy) NSString *currentTitle;
@property (nonatomic) BOOL isVideo;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic) NSInteger queueIndex;
@end
@implementation PlaybackManager
+ (instancetype)shared {
    static PlaybackManager *s; static dispatch_once_t t; dispatch_once(&t, ^{ s = [[PlaybackManager alloc] init]; });
    return s;
}
- (instancetype)init {
    if (self = [super init]) {
        _items = [NSMutableArray array];
        _queueIndex = -1;
        _player = [[AVPlayer alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ended:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}
+ (NSDictionary *)streamItemWithID:(NSString *)vid title:(NSString *)title audioOnly:(BOOL)audio {
    return @{@"vid": vid, @"title": title ? title : vid, @"audio": @(audio)};
}
+ (NSDictionary *)localItemWithPath:(NSString *)path {
    return @{@"path": path, @"title": [path lastPathComponent]};
}
- (NSArray *)queue { return [self.items copy]; }
- (void)playURL:(NSURL *)url title:(NSString *)title video:(BOOL)video {
    [self playItems:@[@{@"url": [url absoluteString], @"title": title ? title : @"Tube", @"video": @(video)}] startingAt:0];
}
- (void)playLocalFile:(NSString *)path {
    [self playItems:@[[PlaybackManager localItemWithPath:path]] startingAt:0];
}
- (void)playItems:(NSArray *)items startingAt:(NSInteger)idx {
    [self.items setArray:items];
    self.queueIndex = idx;
    [self startCurrent];
}
- (void)playQueueAt:(NSInteger)idx {
    if (idx < 0 || idx >= self.items.count) return;
    self.queueIndex = idx;
    [self startCurrent];
}
- (void)enqueueItem:(NSDictionary *)item {
    [self.items addObject:item];
    if (self.queueIndex < 0) { self.queueIndex = 0; [self startCurrent]; }
    else [self changed];
}
- (void)playItemNext:(NSDictionary *)item {
    NSInteger at = self.queueIndex < 0 ? 0 : self.queueIndex + 1;
    if (at > self.items.count) at = self.items.count;
    [self.items insertObject:item atIndex:at];
    if (self.queueIndex < 0) { self.queueIndex = 0; [self startCurrent]; }
    else [self changed];
}
- (void)removeQueueAt:(NSInteger)idx {
    if (idx < 0 || idx >= self.items.count) return;
    [self.items removeObjectAtIndex:idx];
    if (idx == self.queueIndex) {
        if (self.queueIndex >= self.items.count) {
            self.queueIndex = -1;
            [self.player pause];
            self.currentTitle = nil;
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
            [self changed];
        } else [self startCurrent];
    } else {
        if (idx < self.queueIndex) self.queueIndex--;
        [self changed];
    }
}
- (void)clearUpcoming {
    if (self.queueIndex < 0) { [self.items removeAllObjects]; }
    else {
        NSRange r = NSMakeRange(self.queueIndex + 1, self.items.count - self.queueIndex - 1);
        if (r.length) [self.items removeObjectsInRange:r];
    }
    [self changed];
}
- (void)advance:(NSInteger)delta { [self playQueueAt:self.queueIndex + delta]; }
- (void)startCurrent {
    if (self.queueIndex < 0 || self.queueIndex >= self.items.count) return;
    NSDictionary *it = self.items[self.queueIndex];
    NSString *title = it[@"title"] ? it[@"title"] : @"Tube";
    if (it[@"url"]) { [self attach:[NSURL URLWithString:it[@"url"]] title:title video:[it[@"video"] boolValue]]; return; }
    if (it[@"path"]) {
        BOOL v = ![[it[@"path"] pathExtension] isEqualToString:@"m4a"];
        [self attach:[NSURL fileURLWithPath:it[@"path"]] title:title video:v];
        return;
    }
    NSInteger token = self.queueIndex;
    BOOL audio = [it[@"audio"] boolValue];
    [[YTDLPManager shared] streamURLForVideoID:it[@"vid"] audioOnly:audio completion:^(NSString *u, NSString *e) {
        if (token != self.queueIndex) return;
        if (!u) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Error" message:e delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [a show]; return;
        }
        [self attach:[NSURL URLWithString:u] title:title video:!audio];
    }];
}
- (void)attach:(NSURL *)url title:(NSString *)title video:(BOOL)video {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:url]];
    self.currentTitle = title;
    self.isVideo = video;
    [self.player play];
    [self pushInfo:YES];
}
- (void)ended:(NSNotification *)n {
    if (n.object == self.player.currentItem) [self advance:1];
}
- (void)toggle {
    if ([self isPlaying]) [self.player pause];
    else [self.player play];
    [self pushInfo:[self isPlaying]];
}
- (BOOL)isPlaying { return self.player.currentItem && self.player.rate != 0; }
- (void)handleRemoteEvent:(UIEvent *)e {
    if (e.type != UIEventTypeRemoteControl) return;
    if (e.subtype == UIEventSubtypeRemoteControlPlay) { [self.player play]; [self pushInfo:YES]; }
    else if (e.subtype == UIEventSubtypeRemoteControlPause) { [self.player pause]; [self pushInfo:NO]; }
    else if (e.subtype == UIEventSubtypeRemoteControlTogglePlayPause) [self toggle];
    else if (e.subtype == UIEventSubtypeRemoteControlNextTrack) [self advance:1];
    else if (e.subtype == UIEventSubtypeRemoteControlPreviousTrack) [self advance:-1];
}
- (void)changed {
    [[NSNotificationCenter defaultCenter] postNotificationName:TubePlaybackChanged object:nil];
}
- (void)pushInfo:(BOOL)playing {
    if (self.currentTitle) {
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{
            MPMediaItemPropertyTitle: self.currentTitle,
            MPNowPlayingInfoPropertyPlaybackRate: playing ? @1 : @0
        }];
    }
    [self changed];
}
@end
