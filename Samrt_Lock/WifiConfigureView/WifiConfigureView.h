//
//  WifiConfigureView.h
//  Samrt_Lock
//
//  Created by haitao on 16/7/5.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WifiConfigureView : UIView

-(instancetype)initWithFrame:(CGRect)frame;

@property (nonatomic,copy) void(^completeBlock)(NSString *deviceMac);//配置成功返回


@end
