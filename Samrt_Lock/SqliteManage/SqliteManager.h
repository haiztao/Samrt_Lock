//
//  SqliteManager.h
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceModel.h"

@interface SqliteManager : NSObject

+(instancetype)shareSqliteManager;
//蓝牙
- (void)insterDeviceInfo:(DeviceModel *)device;
- (void)deleteDeviceInfo:(DeviceModel *)device;
- (void)updateDeviceInfo:(DeviceModel *)device;
- (NSMutableArray *)getAllDeviceInfo;
- (NSMutableArray *)getDeviceMac:(NSString *)deviceMac;

//wifi
- (void)insterWifiDeviceInfo:(DeviceModel *)device;
- (void)deleteWifiDeviceInfo:(DeviceModel *)device;
- (void)updateWifiDeviceInfo:(DeviceModel *)device;
- (NSMutableArray *)getAllWifiDeviceInfo;
- (NSMutableArray *)getWifiDeviceMac:(NSString *)deviceMac;

@end
