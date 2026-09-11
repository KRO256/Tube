#import <UIKit/UIKit.h>
@interface MiniPlayerBar : UIView
@property (nonatomic, copy) void (^onTap)(void);
- (void)refresh;
@end
