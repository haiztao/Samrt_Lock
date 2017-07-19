//
//  YIndicatorView.h
//  SmartFit Mini
//
//  Created by ADSmartAir on 15/1/23.
//  Copyright (c) 2015年 guzi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class YIndicatorView;

@protocol YIndicatorViewDelegate <NSObject>

-(void)changeStartViewFlag:(YIndicatorView *)indicatorView;

@end

@interface YIndicatorView : UIView

@property(assign,nonatomic)id<YIndicatorViewDelegate>delegate;

+(id)startIndicatorViewAnimatingWithTimeout:(NSInteger)timeout withMessage:(NSString *)message;

+(void)stopIndicatorViewAnimating;

@end






