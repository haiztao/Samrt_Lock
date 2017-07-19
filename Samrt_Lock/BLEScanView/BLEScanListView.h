//
//  BLEScanListView.h
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "DeviceModel.h"
#import "SqliteManager.h"

@interface BLEScanListView : UIView

-(instancetype)initWithFrame:(CGRect)frame DataArray:(NSArray *)dataArray;

@property (nonatomic,copy) void(^selectBlock)(DeviceModel *newDevice);

@end
