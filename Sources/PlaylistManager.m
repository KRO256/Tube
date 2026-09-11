#import "PlaylistManager.h"
NSString *TubePlaylistsChanged = @"TubePlaylistsChanged";
@implementation PlaylistManager
+ (instancetype)shared {
    static PlaylistManager *s; static dispatch_once_t t; dispatch_once(&t, ^{ s = [[PlaylistManager alloc] init]; });
    return s;
}
- (NSArray *)playlists {
    NSArray *p = [[NSUserDefaults standardUserDefaults] objectForKey:@"TubePlaylists"];
    return p ? p : @[];
}
- (void)save:(NSArray *)p {
    [[NSUserDefaults standardUserDefaults] setObject:p forKey:@"TubePlaylists"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:TubePlaylistsChanged object:nil];
}
- (void)createPlaylist:(NSString *)name {
    if (!name.length) return;
    NSMutableArray *p = [[self playlists] mutableCopy];
    [p addObject:@{@"name": name, @"items": @[]}];
    [self save:p];
}
- (void)deletePlaylistAt:(NSInteger)idx {
    NSMutableArray *p = [[self playlists] mutableCopy];
    if (idx < 0 || idx >= p.count) return;
    [p removeObjectAtIndex:idx];
    [self save:p];
}
- (void)addItem:(NSDictionary *)item toPlaylist:(NSInteger)idx {
    NSMutableArray *p = [[self playlists] mutableCopy];
    if (idx < 0 || idx >= p.count) return;
    NSMutableDictionary *pl = [p[idx] mutableCopy];
    NSMutableArray *items = [(pl[@"items"] ? pl[@"items"] : @[]) mutableCopy];
    [items addObject:item];
    pl[@"items"] = items;
    p[idx] = pl;
    [self save:p];
}
- (void)removeItemAt:(NSInteger)row fromPlaylist:(NSInteger)idx {
    NSMutableArray *p = [[self playlists] mutableCopy];
    if (idx < 0 || idx >= p.count) return;
    NSMutableDictionary *pl = [p[idx] mutableCopy];
    NSMutableArray *items = [(pl[@"items"] ? pl[@"items"] : @[]) mutableCopy];
    if (row < 0 || row >= items.count) return;
    [items removeObjectAtIndex:row];
    pl[@"items"] = items;
    p[idx] = pl;
    [self save:p];
}
@end
