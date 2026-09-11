#import <UIKit/UIKit.h>
extern NSString *TubeDownloadsChanged;
extern NSString *TubeDownloadProgress;
@interface DownloadManager : NSObject
+ (instancetype)shared;
- (void)downloadVideo:(NSDictionary *)video audioOnly:(BOOL)audio;
- (NSArray *)activeDownloads;
- (void)cancelDownload:(NSString *)vid;
- (UIViewController *)downloadsViewController;
@end
