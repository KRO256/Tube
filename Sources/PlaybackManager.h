#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
extern NSString *TubePlaybackChanged;
@interface PlaybackManager : NSObject
+ (instancetype)shared;
@property (nonatomic, strong, readonly) AVPlayer *player;
@property (nonatomic, copy, readonly) NSString *currentTitle;
@property (nonatomic, readonly) BOOL isVideo;
- (void)playURL:(NSURL *)url title:(NSString *)title video:(BOOL)video;
- (void)playLocalFile:(NSString *)path;
- (void)toggle;
- (BOOL)isPlaying;
- (void)handleRemoteEvent:(UIEvent *)e;
@end
