#import <UIKit/UIKit.h>
@interface PlayerViewController : UIViewController
- (instancetype)initWithVideo:(NSDictionary *)video audioOnly:(BOOL)audio;
- (instancetype)initWithLocalFile:(NSString *)path;
- (instancetype)initWithShared;
@end
