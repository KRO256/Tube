#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
extern NSString *TubePlaybackChanged;
@interface PlaybackManager : NSObject
+ (instancetype)shared;
@property (nonatomic, strong, readonly) AVPlayer *player;
@property (nonatomic, copy, readonly) NSString *currentTitle;
@property (nonatomic, readonly) BOOL isVideo;
@property (nonatomic, strong, readonly) NSArray *queue;
@property (nonatomic, readonly) NSInteger queueIndex;
+ (NSDictionary *)streamItemWithID:(NSString *)vid title:(NSString *)title audioOnly:(BOOL)audio;
+ (NSDictionary *)localItemWithPath:(NSString *)path;
- (void)playURL:(NSURL *)url title:(NSString *)title video:(BOOL)video;
- (void)playLocalFile:(NSString *)path;
- (void)playItems:(NSArray *)items startingAt:(NSInteger)idx;
- (void)playQueueAt:(NSInteger)idx;
- (void)enqueueItem:(NSDictionary *)item;
- (void)playItemNext:(NSDictionary *)item;
- (void)removeQueueAt:(NSInteger)idx;
- (void)clearUpcoming;
- (void)advance:(NSInteger)delta;
- (void)toggle;
- (BOOL)isPlaying;
- (void)handleRemoteEvent:(UIEvent *)e;
@end
