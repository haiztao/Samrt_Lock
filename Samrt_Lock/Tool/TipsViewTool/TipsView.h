//
//  TipsView.h
//  TodayView
//
//  Created by ADSmartAir on 14/10/31.
//  Copyright (c) 2014年 guzi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define KMainScreenSizeWidth [[UIScreen mainScreen] bounds].size.width
#define KMainScreenSizeHeight [[UIScreen mainScreen] bounds].size.height
@interface TipsView : NSObject

@property (strong,nonatomic)UILabel *tipsLabel;

@property (strong,nonatomic)NSTimer *timer;

+(id)getSingleTipsViewWithTipsString:(NSString *)tipsString andRemindTime:(NSTimeInterval)time;


@end
