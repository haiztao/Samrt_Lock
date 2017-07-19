//
//  BLEManage.h
//  智能鞋
//
//  Created by haitao on 16/4/6.
//  Copyright © 2016年 haitao. All rights reserved.
//

#define LastConnectDevice @"ConnectLastPerpheral"

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEBaseModel.h"
#import "DeviceModel.h"

@protocol BLEManageDelegate <NSObject>

@optional

//返回扫描数组
-(void)showScanPeripheralArray:(NSMutableArray *)dataArray;
//返回锁状态
-(void)showTheLockState:(BOOL)islock;
//成功连接
-(void)connectDeviceSuccessfully;
//蓝牙已断开
-(void)didDisconnectDevice:(DeviceModel *)device;

@optional
-(void)changeDevicePasswordSucceed;

//Sent wrong instruction
-(void)receiveInformationDueToTHeWrongPassword;

//没有权限
-(void)haveNoPermissionsToConnectDevice;

@end


@interface BLEManage : NSObject


@property (nonatomic,weak) id<BLEManageDelegate>delegate;


@property(nonatomic,strong)CBCentralManager *centralManager;
@property(nonatomic,strong)dispatch_queue_t bleGCD;

@property(strong,nonatomic)NSMutableArray * scanPeripheralArray; //扫描到的设备

+ (instancetype)shareBLEManager;

//开始扫描
-(void)startScanBLEDeviceWithAutoScan:(BOOL)autoScan;
//停止扫描
-(void)stopScan;
//连接设备
-(void)connectPeripheral:(DeviceModel *)deviceModel;

-(void)disconnectBLEDevice;

//连接上的设备
@property (nonatomic,strong) DeviceModel *connectDevice;

-(void)writeDataToDeviceSendInstructions:(SendInstructions)sendInstructions;

-(void)changeCurrentDevicePassword:(DeviceModel *)currentDevice AndNewPassword:(NSString *)newPassword;

@end
