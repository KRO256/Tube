#import "YTDLPManager.h"
@implementation YTDLPManager
+ (instancetype)shared {
    static YTDLPManager *s; static dispatch_once_t t; dispatch_once(&t, ^{ s = [[YTDLPManager alloc] init]; });
    return s;
}
- (NSString *)serverBase {
    NSString *s = [[NSUserDefaults standardUserDefaults] stringForKey:@"TubeServer"];
    if (!s.length) s = @"http://192.168.1.2:8080";
    if ([s hasSuffix:@"/"]) s = [s substringToIndex:s.length - 1];
    return s;
}
- (void)setServerBase:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:@"TubeServer"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (NSString *)enc:(NSString *)s {
    return [s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
- (void)get:(NSString *)path completion:(void(^)(NSDictionary *, NSString *))cb {
    NSURL *u = [NSURL URLWithString:[[self serverBase] stringByAppendingString:path]];
    [[[NSURLSession sharedSession] dataTaskWithURL:u completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        NSDictionary *j = nil;
        if (d) j = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (e) cb(nil, [@"server unreachable: " stringByAppendingString:e.localizedDescription]);
            else if (!j) cb(nil, @"bad server response");
            else cb(j, nil);
        });
    }] resume];
}
- (void)search:(NSString *)query max:(NSInteger)max completion:(void(^)(NSArray *, NSString *))cb {
    if (max <= 0) max = 10;
    NSString *p = [NSString stringWithFormat:@"/api/search?q=%@&n=%ld", [self enc:query], (long)max];
    [self get:p completion:^(NSDictionary *j, NSString *e) {
        if (e) cb(nil, e);
        else cb(j[@"results"] ?: @[], [j[@"results"] count] ? nil : @"no results");
    }];
}
- (void)streamURLForVideoID:(NSString *)vid audioOnly:(BOOL)audio completion:(void(^)(NSString *, NSString *))cb {
    NSString *p = [NSString stringWithFormat:@"/api/url?id=%@&audio=%@", [self enc:vid], audio ? @"1" : @"0"];
    [self get:p completion:^(NSDictionary *j, NSString *e) {
        NSString *u = j[@"url"];
        if (e) cb(nil, e);
        else if (!u.length) cb(nil, @"failed to resolve URL");
        else cb(u, nil);
    }];
}
- (void)fetchVersion:(void(^)(NSString *))cb {
    [self get:@"/api/version" completion:^(NSDictionary *j, NSString *e) {
        cb(e ? e : j[@"version"]);
    }];
}
@end
