//
//  DeviceModel.h
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceModel : NSObject

@property (nonatomic,strong) NSString *deviceMac;
@property (nonatomic,strong) NSString *deviceName;
@property (nonatomic,strong) NSString *devicePassword;
@property (nonatomic,strong) NSString *identifier;//蓝牙

+(DeviceModel *)creatWIFIDeviceMac:(NSString *)deviceMac deviceName:(NSString *)deviceName devicePass:(NSString *)devicePassword;

+(DeviceModel *)creatBLEDeviceMac:(NSString *)deviceMac deviceName:(NSString *)deviceName devicePass:(NSString *)devicePassword identifier:(NSString *)identifier;

@end
