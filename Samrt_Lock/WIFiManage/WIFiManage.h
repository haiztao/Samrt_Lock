//
//  WIFiManage.h
//  Samrt_Lock
//
//  Created by haitao on 16/7/14.
//  Copyright © 2016年 haitao. All rights reserved.
//

#define LastConnectWifiDevice @"LastConnectWifiDevice"

#import <Foundation/Foundation.h>

#import "BLEBaseModel.h"
#import "DeviceModel.h"


@protocol WIFiManageDelegate <NSObject>

@optional
//返回锁状态
-(void)showTheLockState:(BOOL)islock;
//更改设备密码成功
-(void)changeDevicePasswordSucceed;

//连接锁成功
-(void)connectDeviceSuccessfully;
@optional
//配置成功返回设备Mac地址
- (void)configureSucceedWithDeviceMac:(NSString *)deviceMac;
@optional
//配置失败
-(void)configureFailWithTipString:(NSString *)tipString;
//Sent wrong instruction
-(void)receiveInformationDueToTHeWrongPassword;
//设备已断开
-(void)wifiDeviceIsDisconnected;

@end


@interface WIFiManage : NSObject

@property (nonatomic,weak) id<WIFiManageDelegate>delegate;
//单例
+ (instancetype)shareWifiManager;

-(void)disconnectWifiDevice;

//配置WiFi网络
- (void)configureWiFiWithwifiName:(NSString *)wifiName Password:(NSString *)pswdStr;
//连接设备
-(void) connectDevice:(DeviceModel *)device;
//修改密码
-(void)changeCurrentDevicePassword:(DeviceModel *)currentDevice AndNewPassword:(NSString *)newPassword;
//开锁
- (void)openTheLockInstruction;
//查询锁状态
-(void)queryLockStateInstruction;


@end
