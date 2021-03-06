//
//  MeViewController.m
//  新闻
//
//  Created by gyh on 15/9/21.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "MeViewController.h"
#import "SDImageCache.h"
#import "SettingHeaderView.h"

#import "SettingGroup.h"
#import "SettingCell.h"
#import "SettingArrowItem.h"
#import "SettingSwitchItem.h"
#import "SettingLabelItem.h"

#import "LoginView.h"
#import "CollectViewController.h"   //收藏
#import "ChatViewController.h"      //帮助与反馈
#import "ShareManager.h"
#import "EMSDK.h"
#import "DownloadTableViewController.h"

@interface MeViewController ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate,EMChatManagerDelegate>

@property (nonatomic , strong) NSString *clearCacheName;

@property (nonatomic , strong) NSMutableArray *arrays;

@property (nonatomic , strong) UIView *fenxiangview;

@property (nonatomic , weak) UIView *headerview;
@property (nonatomic , weak) UITableView *tableview;
@property (nonatomic , copy) NSString * chatCount;     //未读消息数目
@property (nonatomic , strong) NSArray *conversations;

@end

@implementation MeViewController

- (NSMutableArray *)arrays
{
    if (!_arrays) {
        _arrays = [NSMutableArray array];
    }
    return _arrays;
}

- (NSArray *)conversations
{
    if (!_conversations) {
        _conversations = [NSArray array];
    }
    return _conversations;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleThemeChanged) name:Notice_Theme_Changed object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(ChatCountChanged:) name:@"ChatCount" object:nil];
    
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    

    SettingHeaderView *headerview = [[SettingHeaderView alloc]init];
    headerview.loginBlock = ^{
        LoginView *lv = [[LoginView alloc]init];
        [lv show];
    };
    self.headerview = headerview;

    UITableView *tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, -20, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStyleGrouped];
    tableview.delegate = self;
    tableview.dataSource = self;
    [self.view addSubview:tableview];
    tableview.tableHeaderView = headerview;
    self.tableview = tableview;
    
    self.tableview.backgroundColor = [[ThemeManager sharedInstance] themeColor];
    
    [self loadConversations];
    
    [self setupGroup0];
    [self setupGroup2];
}


-(void)loadConversations{
    //获取历史会话记录
    NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
    if (conversations.count == 0) {
        conversations =  [[EMClient sharedClient].chatManager loadAllConversationsFromDB];
    }
    self.conversations = conversations;
    //显示总的未读数
    [self showTabBarBadge];
}

- (void)showTabBarBadge{
    NSInteger totalUnreadCount = 0;
    for (EMConversation *conversation in self.conversations) {
        totalUnreadCount += [conversation unreadMessagesCount];
    }
    DLog(@"未读消息总数:%ld",(long)totalUnreadCount);
    self.chatCount = [NSString stringWithFormat:@"%ld",(long)totalUnreadCount];
}

- (void)handleThemeChanged
{
    ThemeManager *defaultManager = [ThemeManager sharedInstance];
    self.tableview.backgroundColor = [defaultManager themeColor];
    [self.tableview reloadData];
}


#pragma mark - 接收到聊天消息数改变
- (void)ChatCountChanged:(NSNotification *)noti
{
    self.chatCount = noti.object;
    self.arrays = nil;
    [self setupGroup0];
    [self setupGroup2];
    [self.tableview reloadData];
}


- (void)setupGroup0
{
    SettingItem *shoucang = [SettingArrowItem itemWithItem:@"MorePush" title:@"收藏" VcClass:[CollectViewController class]];
    SettingItem *handShake = [SettingSwitchItem itemWithItem:@"handShake" title:@"夜间模式"];
    SettingItem *download = [SettingArrowItem itemWithItem:@"MorePush" title:@"下载列表" VcClass:[DownloadTableViewController class]];

    SettingGroup *group0 = [[SettingGroup alloc]init];
    
    group0.items = @[shoucang,handShake,download];
    [self.arrays addObject:group0];
}

- (void)setupGroup2
{
    IMP_BLOCK_SELF(MeViewController);
    SettingItem *moreHelp = [SettingArrowItem itemWithItem:@"MoreHelp" title:@"帮助与反馈" subtitle:self.chatCount VcClass:[ChatViewController class]];
    SettingItem *moreShare = [SettingArrowItem itemWithItem:@"MoreShare" title:@"分享给好友" VcClass:nil];
    moreShare.optionHandler = ^{
        [[ShareManager sharedInstance] shareWeiboWithTitle:nil images:nil dismissBlock:^{
            [block_self.navigationController popViewControllerAnimated:YES];
        }];
    };
    SettingItem *handShake = [SettingArrowItem itemWithItem:@"handShake" title:@"清除缓存" subtitle:self.clearCacheName];
    handShake.optionHandler = ^{
        [block_self click];
    };
    SettingItem *moreAbout = [SettingArrowItem itemWithItem:@"MoreAbout" title:@"关于" VcClass:nil];
    moreAbout.optionHandler = ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"关于我们" message:@"此项目只供技术交流，不能作为商业用途。\n邮箱:yugao5971@gmail.com\nGitHub:github.com/gaoyuhang" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
    };
    SettingGroup *group1 = [[SettingGroup alloc]init];
    group1.items = @[moreHelp,moreShare,handShake,moreAbout];
    [self.arrays addObject:group1];
}



#pragma mark - tableview代理数据源方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.arrays.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    SettingGroup *group = self.arrays[section];
    return group.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingCell *cell = [SettingCell cellWithTableView:tableView];
    if ([[[ThemeManager sharedInstance] themeName] isEqualToString:@"系统默认"]) {
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor blackColor];

    }else{
        cell.backgroundColor = [[ThemeManager sharedInstance] themeColor];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    SettingGroup *group = self.arrays[indexPath.section];
    cell.item = group.items[indexPath.row];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SettingGroup *group = self.arrays[indexPath.section];
    SettingItem *item = group.items[indexPath.row];
    
    if (item.optionHandler) {
        item.optionHandler();
    }else if ([item isKindOfClass:[SettingArrowItem class]]) {
        SettingArrowItem *arrowItem = (SettingArrowItem *)item;
        if (arrowItem.VcClass == nil) return;
        
        if (arrowItem.VcClass == [ChatViewController class]) {
            
//            ChatViewController *chatVC = [[ChatViewController alloc]init];
//            UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
//            chatVC = [story instantiateViewControllerWithIdentifier:@"ChatViewControl"];
//            chatVC.fromname = @"gaoyuhang";
//            [self.navigationController pushViewController:chatVC animated:YES];

        } else if (arrowItem.VcClass == [DownloadTableViewController class]) {
            DownloadTableViewController *vc = [DownloadTableViewController new];
            [self.navigationController pushViewController:vc animated:YES];
        } else{
            UIViewController *vc = [[arrowItem.VcClass alloc]init];
            vc.view.backgroundColor = [UIColor whiteColor];
            vc.title = arrowItem.title;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}


#pragma mark - 计算偏移量控制状态栏的颜色
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.contentOffset.y;
    CGFloat hey = CGRectGetMaxY(self.headerview.frame);
    if (y <= -30 || y >= hey-40) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    }else{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}


#pragma mark - 清除缓存
- (void)click
{
//    IMP_BLOCK_SELF(MeViewController);
    @weakify_self;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].windows firstObject] animated:YES];
//    hud.mode = MBProgressHUDModeAnnularDeterminate;
//    hud.backgroundView.backgroundColor = [UIColor colorWithWhite:0.f alpha:.2f];
    hud.label.text = @"急速清理中";
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @strongify_self;
        // Do something...
        [[SDImageCache sharedImageCache] clearDisk];
        [[SDImageCache sharedImageCache] clearMemory];
        [[AVCacheManager sharedInstance] clearDisk];
        self.clearCacheName = @"0.0KB";
        self.arrays = nil;
        
        [NSThread sleepForTimeInterval:1.0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupGroup0];
            [self setupGroup2];
            [self.tableview reloadData];

            [MBProgressHUD hideHUDForView:[[UIApplication sharedApplication].windows firstObject] animated:YES];
        });
    });
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableview.delegate = self;
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    float tmpSize = [[SDImageCache sharedImageCache] getSize];
    NSString *clearCacheName = tmpSize >= 1 ? [NSString stringWithFormat:@"%.1fMB",tmpSize/(1024*1024)] : [NSString stringWithFormat:@"%.1fKB",tmpSize * 1024];
    
    float movieSize = [[AVCacheManager sharedInstance] getSize];
    NSString *movieSizeString = movieSize >= 1 ? [NSString stringWithFormat:@"%.1fMB",movieSize/(1024*1024)] : [NSString stringWithFormat:@"%.1fKB",movieSize * 1024];

    self.clearCacheName = [NSString stringWithFormat:@"【%@】【%@】",clearCacheName,movieSizeString];
    
    self.arrays = nil;
    [self setupGroup0];
    [self setupGroup2];
    [self.tableview reloadData];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.tableview.delegate = nil;
    [self.navigationController setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

@end
