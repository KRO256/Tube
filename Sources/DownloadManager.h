#import <UIKit/UIKit.h>
@interface DownloadManager : NSObject
+ (instancetype)shared;
- (void)downloadVideo:(NSDictionary *)video audioOnly:(BOOL)audio;
- (UIViewController *)downloadsViewController;
@end
