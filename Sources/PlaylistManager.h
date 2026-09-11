#import <Foundation/Foundation.h>
extern NSString *TubePlaylistsChanged;
@interface PlaylistManager : NSObject
+ (instancetype)shared;
- (NSArray *)playlists;
- (void)createPlaylist:(NSString *)name;
- (void)deletePlaylistAt:(NSInteger)idx;
- (void)addItem:(NSDictionary *)item toPlaylist:(NSInteger)idx;
- (void)removeItemAt:(NSInteger)row fromPlaylist:(NSInteger)idx;
@end
