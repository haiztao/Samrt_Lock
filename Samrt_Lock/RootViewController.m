//
//  RootViewController.m
//  SmartLock
//
//  Created by haitao on 16/5/18.
//  Copyright © 2016年 haitao. All rights reserved.
//


enum{
    BLEModelTag = 100,
    WiFiModelTag = 101,
};

#define KMainScreenHeigth [UIScreen mainScreen].bounds.size.height
#define KMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define BottonViewHeight 80
#define YColorRGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define ConnectModel @"ConnectModel"



#import "RootViewController.h"
#import "QRadioButton.h"
#import <Masonry.h>
#import "BLEModelViewController.h"
#import "WIFIModelViewController.h"


#import "SqliteManager.h"

@interface RootViewController ()
{
    UIViewController *currentVC;

    SqliteManager *sqliteManger;

}
@property (nonatomic,strong) BLEModelViewController *bleModelVC;

@property (nonatomic,strong) WIFIModelViewController *wifiModelVC;


@end


@implementation RootViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    sqliteManger = [SqliteManager shareSqliteManager];
    
    // 防止block中的循环引用
    __weak typeof(self) weakSelf = self;
    
     UIImageView *backgroundImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, KMainScreenWidth, KMainScreenHeigth)];
    backgroundImageView.image = [UIImage imageNamed:@"01"];
    
    [self.view addSubview:backgroundImageView];

    // 使用mas_makeConstraints添加约束
    [backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.top.equalTo(weakSelf.view);
        make.left.equalTo(weakSelf.view);
        make.bottom.equalTo(weakSelf.view);
        make.right.equalTo(weakSelf.view);
    }];

    
    float y = KMainScreenHeigth - BottonViewHeight;
    UIView *whiteView = [[UIView alloc]initWithFrame:CGRectMake(0, y, KMainScreenWidth, BottonViewHeight)];
    whiteView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:whiteView];
    
    
    // 使用mas_makeConstraints添加约束
    [whiteView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.height.equalTo(@80);
        make.left.equalTo(weakSelf.view);
        make.bottom.equalTo(weakSelf.view);
        make.right.equalTo(weakSelf.view);
    }];
    
     UIView *unuseView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    unuseView.center = whiteView.center;
    unuseView.backgroundColor = [UIColor clearColor];
    [whiteView addSubview:unuseView];
    
    [unuseView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.centerX.equalTo(whiteView.mas_centerX);
        make.centerY.equalTo(whiteView.mas_centerY);
    }];
    
    
    QRadioButton *blueToothButton = [[QRadioButton alloc]initWithDelegate:self groupId:ConnectModel title:NSLocalizedString(@"BLE", nil)];
    blueToothButton.tag = BLEModelTag;
    [whiteView addSubview:blueToothButton];
    [blueToothButton setChecked:YES];
    
    [blueToothButton mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.top.equalTo(whiteView).offset(4);
        make.width.equalTo(@150);
        make.bottom.equalTo(whiteView).offset(-4);
        make.right.equalTo(unuseView).offset(-50);
    }];
    

    QRadioButton *wifiButton = [[QRadioButton alloc]initWithDelegate:self groupId:ConnectModel title:NSLocalizedString(@"WIFI", nil)];
    wifiButton.tag = WiFiModelTag;
    [whiteView addSubview:wifiButton];

   
    [wifiButton mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.top.equalTo(whiteView).offset(4);
        make.width.equalTo(@150);
        make.bottom.equalTo(whiteView).offset(-4);
        make.left.equalTo(unuseView).offset(50);
    }];
    
//    [self addsubViewController:self.bleModelVC];
//    currentVC = self.bleModelVC;
    
}



#pragma mark - 选择按钮delegate
- (void)didSelectedRadioButton:(QRadioButton *)radio groupId:(NSString *)groupId{
    
    if ([groupId isEqualToString:ConnectModel]) {
        
        if (radio.checked == YES) {
           
             [self removeFromParent:currentVC];
            
            switch (radio.tag) {
                case BLEModelTag:
                {
                    
                    [self addsubViewController:self.bleModelVC];
           
                    currentVC = self.bleModelVC;
                    break;
                }
                case WiFiModelTag:
                {
                    
                    [self addsubViewController:self.wifiModelVC];
                    currentVC = self.wifiModelVC;
                    break;
                }
            }
            
        }else{
            NSLog(@"none");
        }
        
    }
    
}


-(BLEModelViewController *)bleModelVC{
    if (!_bleModelVC) {
        _bleModelVC = [[BLEModelViewController alloc]init];
    }
    return _bleModelVC;
}
-(WIFIModelViewController *)wifiModelVC{
    if (!_wifiModelVC) {
        _wifiModelVC = [[WIFIModelViewController alloc]init];
    }
    return _wifiModelVC;
}

-(void) addsubViewController:(UIViewController *)subVC{
    
    [self addChildViewController:subVC];
    [self.view addSubview:subVC.view];
    [subVC didMoveToParentViewController:self];
    
//    subVC.view.frame = CGRectMake(0, 0, KMainScreenWidth, KMainScreenHeigth-80);
    
    // 防止block中的循环引用
    __weak typeof(self) weakSelf = self;
    [subVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.top.equalTo(weakSelf.view);
        make.left.equalTo(weakSelf.view);
        make.bottom.equalTo(weakSelf.view).offset(-80);
        make.right.equalTo(weakSelf.view);
    }];
}
-(void)removeFromParent:(UIViewController *)sub
{
    [sub.view removeFromSuperview];
    [sub willMoveToParentViewController:nil];
    [sub removeFromParentViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
