//
//  DeviceModel.m
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import "DeviceModel.h"

@implementation DeviceModel

+(DeviceModel *)creatWIFIDeviceMac:(NSString *)deviceMac deviceName:(NSString *)deviceName devicePass:(NSString *)devicePassword{
    
    DeviceModel *model = [[DeviceModel alloc]init];
    model.deviceMac = deviceMac;
    model.deviceName = deviceName;
    model.devicePassword = devicePassword;
    return model;
}

+(DeviceModel *)creatBLEDeviceMac:(NSString *)deviceMac deviceName:(NSString *)deviceName devicePass:(NSString *)devicePassword identifier:(NSString *)identifier{
    
    DeviceModel *model = [[DeviceModel alloc]init];
    model.deviceMac = deviceMac;
    model.deviceName = deviceName;
    model.devicePassword = devicePassword;
    model.identifier = identifier;
    return model;
}

-(NSString *)description{
    NSString *string = [NSString stringWithFormat:@" _deviceMac:%@  _deviceName:%@ _devicePassword:%@ identifier:%@",_deviceMac ,_deviceName,_devicePassword,_identifier];
    return string;
}



@end
