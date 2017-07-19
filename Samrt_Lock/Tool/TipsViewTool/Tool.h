//
//  Tool.h
//  WaterDispenser
//
//  Created by saiyi on 15/10/20.
//  Copyright (c) 2015年 CD. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tool : NSObject

//判断是否为正确的手机号码
+(BOOL)checkThePhoneNumber:(NSString *)phoneNumber;

// 获取当前日期
+(NSString*)nowDate;

//获取重复的是周几
+ (NSString *)showWeekDay:(NSString *)weekInfo;

// 获取是星期几
+(NSInteger) getweekdate;

// 获取设定的时间
+(int)getMinu:(NSDate*)date;

// 获取特定时间所在周的日期
+(NSArray*)getWeek:(NSString *)datestr;

// 当前月
+(NSString *)nowMonth;

//当前年份
+(NSString *)yearr;

//二进制转十进制
+(int)decimalSystemWithWeekDay:(NSString *)weekInfo;;

+(NSArray*)getTime:(NSString *)time;

// 取消某个本地推送通知
+ (void)cancelLocalNotificationWithKey:(NSString *)key;

//去除数组中重复的数据得到新数组
+ (NSMutableArray *)getIsNotEqualDateByArray:(NSArray *)weAr;

@end
