#import "SettingsViewController.h"
#import "YTDLPManager.h"
@interface SettingsViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) NSString *ver;
@end
@implementation SettingsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
}
- (void)viewWillAppear:(BOOL)a {
    [super viewWillAppear:a];
    self.ver = @"...";
    [self.tableView reloadData];
    [[YTDLPManager shared] fetchVersion:^(NSString *v) {
        self.ver = v; [self.tableView reloadData];
    }];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)t { return 1; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return 2; }
- (NSString *)tableView:(UITableView *)t titleForHeaderInSection:(NSInteger)s { return @"yt-dlp server (PC/RPi)"; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)p {
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    if (p.row == 0) { c.textLabel.text = @"Server"; c.detailTextLabel.text = [[YTDLPManager shared] serverBase]; }
    else { c.textLabel.text = @"yt-dlp"; c.detailTextLabel.text = self.ver; }
    c.detailTextLabel.font = [UIFont systemFontOfSize:11];
    return c;
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)p {
    [t deselectRowAtIndexPath:p animated:YES];
    if (p.row != 0) return;
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Server" message:@"http://192.168.1.2:8080" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    a.alertViewStyle = UIAlertViewStylePlainTextInput;
    [a textFieldAtIndex:0].text = [[YTDLPManager shared] serverBase];
    [a show];
}
- (void)alertView:(UIAlertView *)a clickedButtonAtIndex:(NSInteger)i {
    if (i == 1) {
        [[YTDLPManager shared] setServerBase:[a textFieldAtIndex:0].text];
        [self viewWillAppear:NO];
    }
}
@end
