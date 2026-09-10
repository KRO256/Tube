#import <Foundation/Foundation.h>
@interface YTDLPManager : NSObject
+ (instancetype)shared;
- (NSString *)serverBase;
- (void)setServerBase:(NSString *)s;
- (void)search:(NSString *)query max:(NSInteger)max completion:(void(^)(NSArray *results, NSString *err))cb;
- (void)streamURLForVideoID:(NSString *)vid audioOnly:(BOOL)audio completion:(void(^)(NSString *url, NSString *err))cb;
- (void)fetchVersion:(void(^)(NSString *v))cb;
@end
