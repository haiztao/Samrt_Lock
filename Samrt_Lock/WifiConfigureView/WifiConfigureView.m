//
//  WifiConfigureView.m
//  Samrt_Lock
//
//  Created by haitao on 16/7/5.
//  Copyright © 2016年 haitao. All rights reserved.
//

#define KMainScreenSizeWidth [[UIScreen mainScreen] bounds].size.width
#define KMainScreenSizeHeight [[UIScreen mainScreen] bounds].size.height
#define YColorRGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#import "WifiConfigureView.h"


#import <SystemConfiguration/CaptiveNetwork.h>

#import "YIndicatorView.h"

#import "WIFiManage.h"


@interface WifiConfigureView()<UIAlertViewDelegate,UITextFieldDelegate,WIFiManageDelegate>


@property (strong, nonatomic)  UITextField *wifiTextField;

@property (strong, nonatomic)  UITextField *passwordTextField;

@property (nonatomic,strong) NSString *deviceMac;

@property (nonatomic,strong) NSString *deviceIP;

@property (nonatomic,strong) WIFiManage *wifiManage;

@end

@implementation WifiConfigureView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.wifiManage = [WIFiManage shareWifiManager];
        
        UIView *backgroundView = [[UIView alloc]initWithFrame:frame];
        backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        [self addSubview:backgroundView];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(disMissTheView)];
        singleTap.numberOfTapsRequired = 1;
        [backgroundView addGestureRecognizer:singleTap];
        
        UIView *functionView = [[UIView alloc]initWithFrame:CGRectMake((KMainScreenSizeWidth - 300)/ 2, KMainScreenSizeHeight * 0.1, 300, 300)];
        
        functionView.backgroundColor = [UIColor whiteColor];
        [self addSubview:functionView];
        
        UILabel *headerLabel = [self createLabelWithFrame:CGRectMake(0, 20, 300, 20) infoText:NSLocalizedString(@"input_Wifi_info", nil)];
        [functionView addSubview:headerLabel];
        
        UILabel *ssidLabel = [self createLabelWithFrame:CGRectMake(0, 70, 80, 20) infoText:NSLocalizedString(@"wifiName", nil)];
        [functionView addSubview:ssidLabel];
        
        self.wifiTextField = [[UITextField alloc]initWithFrame:CGRectMake(90, 60, 180, 40)];
        self.wifiTextField.borderStyle = UITextBorderStyleRoundedRect;
        [functionView addSubview:self.wifiTextField];
        
        UILabel *passwordLabel = [self createLabelWithFrame:CGRectMake(0, 120, 80, 20) infoText:NSLocalizedString(@"password", nil)];
        [functionView addSubview:passwordLabel];
        
        self.passwordTextField = [[UITextField alloc]initWithFrame:CGRectMake(90, 110, 180, 40)];
        self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
        [self.passwordTextField setSecureTextEntry:YES];
        self.passwordTextField.delegate = self;
        [functionView addSubview:self.passwordTextField];
        
        
        UIButton *checkButton = [[UIButton alloc]initWithFrame:CGRectMake(90, 180, 30, 30)];
        [checkButton setImage:[UIImage imageNamed:@"check2"] forState:UIControlStateNormal];
        [checkButton addTarget:self action:@selector(showPasswordNumber:) forControlEvents:UIControlEventTouchUpInside];
        [functionView addSubview:checkButton];
        
        
        
        UILabel *passLabel = [self createLabelWithFrame:CGRectMake(123, 180, 160, 30) infoText:NSLocalizedString(@"显示密码", nil)];
        passLabel.textColor = [UIColor blackColor];
        passLabel.textAlignment = NSTextAlignmentLeft;
        passLabel.adjustsFontSizeToFitWidth = YES;
        [functionView addSubview:passLabel];
        
        UIButton *configureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        configureButton.frame = CGRectMake(90, 230, 170, 50);
        [configureButton setTitle:NSLocalizedString(@"Configure_wifi", nil) forState:UIControlStateNormal];
        [configureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [configureButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        configureButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        configureButton.backgroundColor = YColorRGB(207, 208, 209);
        [configureButton addTarget:self action:@selector(configureWiFi:) forControlEvents:UIControlEventTouchUpInside];
        [functionView addSubview:configureButton];
        
        
        [self showWifiSsid];
        self.passwordTextField.text = [self getspwdByssid:self.wifiTextField.text];
        
    }
    return self;
}

-(void)showPasswordNumber:(UIButton *)button{
    button.selected = !button.selected;;
    
    if (button.selected == YES) {
        [button setImage:[UIImage imageNamed:@"check1"] forState:UIControlStateNormal];
        [self.passwordTextField setSecureTextEntry:NO];
    }else{
        [button setImage:[UIImage imageNamed:@"check2"] forState:UIControlStateNormal];
        [self.passwordTextField setSecureTextEntry:YES];
    }
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    return YES;
}

- (BOOL)acceptOnInterface:(NSString *)interface port:(UInt16)port error:(NSError **)errPtr{
    return YES;
}
- (void)showWifiSsid
{
    BOOL wifiOK= FALSE;
    NSDictionary *ifs;
    NSString *ssid;
    UIAlertView *alert;
    if (!wifiOK)
    {
        ifs = [self fetchSSIDInfo];
        ssid = [ifs objectForKey:@"SSID"];
        if (ssid != nil)
        {
            wifiOK= TRUE;
            self.wifiTextField.text = ssid;
        }
        else
        {
            alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"提示", nil) message:NSLocalizedString(@"请连接WiFi", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil];
            alert.delegate=self;
            [alert show];
        }
    }
}
//wifi信息
- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) { break; }
    }
    return info;
}

-(NSString *)getspwdByssid:(NSString * )mssid{
    NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
    return [def objectForKey:mssid];
}
-(void)savePswd{
    NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
    [def setObject:self.passwordTextField.text forKey:self.wifiTextField.text];
}

#pragma mark - 配置WiFi
- (void)configureWiFi:(UIButton *)sender {
    
    [YIndicatorView startIndicatorViewAnimatingWithTimeout:100 withMessage:NSLocalizedString(@"配置中...", nil)];
    
    NSString * ssidStr= self.wifiTextField.text;
    NSString * pswdStr = self.passwordTextField.text;
    [self savePswd];
    [self.wifiManage configureWiFiWithwifiName:ssidStr Password:pswdStr];
    
}




-(UILabel *)createLabelWithFrame:(CGRect)frame infoText:(NSString *)infoText{
    
    UILabel *myLabel = [[UILabel alloc]initWithFrame:frame];
    myLabel.textAlignment = NSTextAlignmentCenter;
    myLabel.textColor = [UIColor lightGrayColor];
    myLabel.text = infoText;
    
    return myLabel;
}

-(void)disMissTheView{
    self.superview.userInteractionEnabled = NO;
    [UIView animateWithDuration:1 animations:^{
        
    } completion:^(BOOL finished) {
        self.superview.userInteractionEnabled = YES;
        [self removeFromSuperview];
    }];
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self endEditing:YES];
}





@end
