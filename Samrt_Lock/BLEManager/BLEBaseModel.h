//
//  BLEBaseModel.h
//  智能鞋
//
//  Created by haitao on 16/4/8.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEBaseModel : NSObject


typedef NS_ENUM(NSInteger, SendInstructions){

    /**
     *  数据上传
     */
    ShakeHand = 1000,//1、握手
    
    LockState , //2、锁的状态查询
    
    OpenLock,//4、锁的控制
    
    HeartBeat,//5、心跳包
    
};



@end
