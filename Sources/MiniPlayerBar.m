#import "MiniPlayerBar.h"
#import "PlaybackManager.h"
@interface MiniPlayerBar ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *btn;
@end
@implementation MiniPlayerBar
- (instancetype)initWithFrame:(CGRect)f {
    if (self = [super initWithFrame:f]) {
        self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.btn = [UIButton buttonWithType:UIButtonTypeSystem];
        self.btn.frame = CGRectMake(8, 4, 40, 40);
        self.btn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [self.btn addTarget:self action:@selector(tapBtn) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.btn];
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(56, 4, f.size.width - 64, 40)];
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.label.font = [UIFont systemFontOfSize:13];
        [self addSubview:self.label];
        UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapBar)];
        [self addGestureRecognizer:g];
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, f.size.width, 0.5)];
        line.backgroundColor = [UIColor lightGrayColor];
        line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:line];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:TubePlaybackChanged object:nil];
        [self refresh];
    }
    return self;
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }
- (void)tapBtn { [[PlaybackManager shared] toggle]; }
- (void)tapBar { if (self.onTap) self.onTap(); }
- (void)refresh {
    PlaybackManager *m = [PlaybackManager shared];
    self.hidden = !m.currentTitle;
    self.label.text = m.currentTitle;
    [self.btn setTitle:[m isPlaying] ? @"II" : @">" forState:UIControlStateNormal];
}
@end
