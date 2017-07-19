//
//  Tool.m
//  WaterDispenser
//
//  Created by saiyi on 15/10/20.
//  Copyright (c) 2015年 CD. All rights reserved.
//

#import "Tool.h"
#import "AppDelegate.h"

@implementation Tool

#pragma mark - 手机号码验证
+(BOOL)checkThePhoneNumber:(NSString *)phoneNumber{
    if (phoneNumber.length == 0) {
        

         return NO;
    }
     //手机验证正则表达式
    //1[0-9]{10}
      //^((13[0-9])|(15[^4,\\D])|(18[0,5-9]))\\d{8}$
     //    NSString *regex = @"[0-9]{11}";
    NSString *regex = @"^((13[0-9])|(147)|(15[^4,\\D])|(18[0,0-9]))\\d{8}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    BOOL isMatch = [pred evaluateWithObject:phoneNumber];
    
    if (!isMatch) {
//        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"提示" message:@"请输入正确的手机号码" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//        [alert show];
        return NO;
    }
    
    return YES;
}

#pragma mark - 当前日期
+(NSString*)nowDate{
    
    NSDateFormatter *formartter=[[NSDateFormatter alloc]init];
    [formartter setDateFormat:@"yyyy.MM.dd"];
    NSString *Datestr=[formartter stringFromDate:[NSDate date]];
    
    return Datestr;
}

#pragma mark - 当前月
+(NSString *)nowMonth{
    
    NSDateFormatter *formartter=[[NSDateFormatter alloc]init];
    [formartter setDateFormat:@"yyyy.MM."];
    NSString *Datestr=[formartter stringFromDate:[NSDate date]];
    return Datestr;
    
}

+(NSString *)yearr{
    
    NSDateFormatter *formartter=[[NSDateFormatter alloc]init];
    [formartter setDateFormat:@"yyyy."];
    NSString *Datestr=[formartter stringFromDate:[NSDate date]];
    return Datestr;
    
}


#pragma mark - 获取所传时间数据是当年的第几周
+(NSString *)getWeekBySelectDate:(NSString *)selectDate{
    
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSInteger unitFlags = NSCalendarUnitWeekOfMonth|NSCalendarUnitWeekday;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy.MM.dd"];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    NSDate *now = [dateFormatter dateFromString:selectDate];
    
    NSDateComponents *comps = [calendar components:unitFlags fromDate:now];
    
    NSInteger week = [comps weekday];
    
    NSString * selectStr=[NSString stringWithFormat:@"%ld",(long)week];
    
    return selectStr;

}


+ (NSString *)showWeekDay:(NSString *)weekInfo {
    
    NSMutableString *result=[NSMutableString stringWithFormat:@""];
    if (weekInfo == nil ) {
        return result;
    }
    
    NSArray *week = [weekInfo componentsSeparatedByString:@"|"];
    
    if (week.count == 7) {
        [result appendString:@"每天"];
        
    } else if (week.count == 2 && [[week objectAtIndex:0]intValue] == 0 && [[week objectAtIndex:1]intValue] == 6) {
        
        [result appendString:@"周末"];
    } else if (week.count == 5 && !([[week objectAtIndex:0]intValue] == 0 || [[week objectAtIndex:4]intValue] == 6)) {
        [result appendString:@"工作日"];
    } else {
        
        for (NSNumber *num in week) {
            switch ([num intValue]) {
                case 0:
                    [result appendString:@" 周一"];
                    break;
                case 1:
                    [result appendString:@" 周二"];
                    break;
                case 2:
                    [result appendString:@" 周三"];
                    break;
                case 3:
                    [result appendString:@" 周四"];
                    break;
                case 4:
                    [result appendString:@" 周五"];
                    break;
                case 5:
                    [result appendString:@" 周六"];
                    break;
                case 6:
                    [result appendString:@" 周日"];
                    break;
                default:
                    break;
            }
        }
    }
    
    return result;
}

#pragma mark - 获取当前是星期几
+(NSInteger) getweekdate{
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitDay fromDate:now];
    // 得到星期几
    // 1(星期一) 2(星期二) 3(星期三) 4(星期四) 5(星期五) 6(星期六) 0(星期天)
    NSInteger weekDay = [comp weekday]-1;
    
   
    return weekDay;
    
}


#pragma mark -获取设定的时间
+(int)getMinu:(NSDate*)date{
    NSDateFormatter *hour=[[NSDateFormatter alloc]init];
    [hour setDateFormat:@"HH"];
    NSString *hourStr=[hour stringFromDate:date];
    int h=[hourStr intValue]*3600;
    
    NSDateFormatter *minute=[[NSDateFormatter alloc]init];
    [minute setDateFormat:@"mm"];
    NSString *minuteStr=[minute stringFromDate:date];
    int mu=[minuteStr intValue]*60;
    
    int getMinu=h+mu;
    return getMinu;
    
}

#pragma mark - 获取特定时间所在周的日期
+(NSArray*)getWeek:(NSString *)datestr{
    NSMutableArray *arr=[[NSMutableArray alloc]initWithCapacity:0];
    NSMutableArray *ar1=[[NSMutableArray alloc]initWithCapacity:0];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy.MM.dd"];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    [dateFormatter setTimeZone:timeZone];
    
    NSDate *now = [dateFormatter dateFromString:datestr];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday|NSCalendarUnitDay
                                         fromDate:now];
    //获取当前是周几、该月的第几天
    NSInteger weekDay = [comp weekday]-1;
    NSInteger day = [comp day];
    
    // 计算当前日期和这周的星期一和星期天差的天数
    NSInteger firstDiff=0;
    NSInteger lastDiff = 0;
    
    if (weekDay == 1) {
        [arr addObject:datestr];
        
    }else{
        
        firstDiff =  weekDay ;
        lastDiff = 7 - weekDay;
    }
    
    NSInteger begin=firstDiff;
    NSInteger en=lastDiff;
    
      for (int i=0 ; i<begin; i++) {
        
        // 在当前日期(去掉了时分秒)基础上加上差的天数
        NSDateComponents *nextDayComp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        [nextDayComp setDay:day-i];
        
        NSDate *firstDayOfWeek= [calendar dateFromComponents:nextDayComp];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy.MM.dd"];
        NSString *endateStr = [NSString stringWithFormat:@"%@",[formater stringFromDate:firstDayOfWeek]];
        
        [arr addObject:endateStr];
        
    }
    for (NSInteger k=arr.count; k>0; k--) {
        
        NSString *str=[arr objectAtIndex:k-1];
        
        [ar1 addObject:str];//正序添加
        
    }
      
    for (int i=0; i<en; i++) {
        
        // 在当前日期(去掉了时分秒)基础上加上差的天数
        NSDateComponents *nextDayComp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
        [nextDayComp setDay:day+i+1];
        
        NSDate *firstDayOfWeek= [calendar dateFromComponents:nextDayComp];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy.MM.dd"];
        NSString *endateStr = [NSString stringWithFormat:@"%@",[formater stringFromDate:firstDayOfWeek]];
        
        [arr addObject:endateStr];
        
    }
    
    return ar1;
}


//二进制转十进制
+(NSString *)toDecimalSystemWithBinarySystem:(NSString *)binary{
    int ll = 0 ;
    int temp = 0 ;
    
    for (int i = 0; i < binary.length; i ++){
        temp = [[binary substringWithRange:NSMakeRange(i, 1)] intValue];
        temp = temp * powf(2, binary.length - i - 1);
        ll += temp;
     }
    NSString * result = [NSString stringWithFormat:@"%d",ll];

    return result  ;
    
}

+(int)decimalSystemWithWeekDay:(NSString *)weekInfo{
    
    NSMutableString *result=[NSMutableString stringWithFormat:@"01111111"];
    
    if (weekInfo == nil ) {
        return 127;
    }
    
    NSArray *week = [weekInfo componentsSeparatedByString:@"|"];
    
    if (week.count == 7) {
        
        return 127;
        
    }else {
        NSMutableArray *resultArr=[[NSMutableArray alloc]initWithObjects:@"0",@"0",@"0",@"0",@"0",@"0",@"0",@"0", nil];
        for (NSString *str in week) {
            
            if ([str isEqualToString:@"0"]) {
                [resultArr replaceObjectAtIndex:7 withObject:@"1"];
            }
            if ([str isEqualToString:@"1"]) {
                [resultArr replaceObjectAtIndex:6 withObject:@"1"];
            }
            if ([str isEqualToString:@"2"]) {
                [resultArr replaceObjectAtIndex:5 withObject:@"1"];
            }
            if ([str isEqualToString:@"3"]) {
                [resultArr replaceObjectAtIndex:4 withObject:@"1"];
            }
            if ([str isEqualToString:@"4"]) {
                [resultArr replaceObjectAtIndex:3 withObject:@"1"];
            }
            if ([str isEqualToString:@"5"]) {
                [resultArr replaceObjectAtIndex:2 withObject:@"1"];
            }
            if ([str isEqualToString:@"6"]) {
                [resultArr replaceObjectAtIndex:1 withObject:@"1"];
            }
            
        }
        result=[NSMutableString stringWithFormat:@"0%@%@%@%@%@%@%@",[resultArr objectAtIndex:1],[resultArr objectAtIndex:2],[resultArr objectAtIndex:3],[resultArr objectAtIndex:4],[resultArr objectAtIndex:5],[resultArr objectAtIndex:6],[resultArr objectAtIndex:7]];
        
         NSString *str=[self toDecimalSystemWithBinarySystem:result];
        int arrr=[str intValue];
        
        return arrr;
    }
    
    
}

+(NSArray*)getTime:(NSString *)time{
    
    NSArray *arr=[time componentsSeparatedByString:@":"];
    return arr;
    
}

// 取消某个本地推送通知
+ (void)cancelLocalNotificationWithKey:(NSString *)key {
    // 获取所有本地通知数组
    NSArray *localNotifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    
    for (UILocalNotification *notification in localNotifications) {
        NSDictionary *userInfo = notification.userInfo;
        if (userInfo) {
            // 根据设置通知参数时指定的key来获取通知参数
            NSString *info = userInfo[key];
            
            // 如果找到需要取消的通知，则取消
            if (info != nil) {
                [[UIApplication sharedApplication] cancelLocalNotification:notification];
                break;
            }
        }
    }
}

//去除数组中重复的数据得到新数组
+ (NSMutableArray *)getIsNotEqualDateByArray:(NSArray *)weAr
{
    //相似日期去重
    NSMutableArray *newWeArr = [NSMutableArray arrayWithCapacity:0];
    
    for (int i = 0; i < weAr.count; i ++)
    {
        if (newWeArr.count == 0) {
            [newWeArr addObject:weAr[i]];
            continue;
        }
        if (![newWeArr[newWeArr.count-1] isEqualToString:weAr[i]])
        {
            [newWeArr addObject:weAr[i]];
        }
        
    }
    
    return newWeArr;

}



@end
