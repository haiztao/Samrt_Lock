//
//  YIndicatorView.m
//  SmartFit Mini
//
//  Created by ADSmartAir on 15/1/23.
//  Copyright (c) 2015年 guzi. All rights reserved.
//

#import "YIndicatorView.h"
#import "AppDelegate.h"

#define YBlack [UIColor colorWithRed:50.0/255.0 green:142.0/255.0 blue:236.0/255.0 alpha:0.8f]
#define KMainScreenHeigth [UIScreen mainScreen].bounds.size.height
#define KMainScreenWidth [UIScreen mainScreen].bounds.size.width

static YIndicatorView *indicatorView = nil;

@interface YIndicatorView ()

@property (strong,nonatomic)UIActivityIndicatorView *activityView;

@property (strong,nonatomic)UIView *backView;

@property (strong,nonatomic)UIView *activityBackView;

@property (strong,nonatomic)NSTimer * timer;

@end


@implementation YIndicatorView

-(id)initWithFrame:(CGRect)frame withMessage:(NSString *)message{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
//        self.alpha = 1;
        self.userInteractionEnabled = NO;
        
        self.backView =[[UIView alloc]initWithFrame:frame];
        self.backView.backgroundColor = [UIColor blackColor];
        self.backView.alpha = 0.2;
        [self addSubview:self.backView];
        
        self.activityBackView = [[UIView alloc]initWithFrame:frame];
        
        
        self.activityBackView.backgroundColor = [UIColor blackColor];
        self.activityBackView.alpha = 0.7;
        [self addSubview:self.activityBackView];
        
        self.activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        self.activityView.center = CGPointMake(self.center.x, self.center.y);
        self.activityView.color = [UIColor grayColor]; //YBlack;
        [self addSubview:self.activityView];
        
//        NSLog(@"self.activityView.frame = %@",NSStringFromCGRect(self.activityView.frame));
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.activityView.frame.origin.y + 50, KMainScreenWidth, self.activityView.frame.size.height)];
        label.text = message;
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:17];
        [self addSubview:label];
        
    }
    return self;
}

+(id)startIndicatorViewAnimatingWithTimeout:(NSInteger)timeout withMessage:(NSString *)message{
    
    
    [indicatorView removeFromSuperview];
    if (indicatorView == nil) {
        indicatorView = [[YIndicatorView alloc]initWithFrame:[UIScreen mainScreen].bounds withMessage:message];
    }
    
    [indicatorView.timer invalidate];
    indicatorView.timer = nil;
    indicatorView.timer = [NSTimer scheduledTimerWithTimeInterval:timeout target:indicatorView selector:@selector(timerAclick:) userInfo:nil repeats:NO];
    AppDelegate *appD = [UIApplication sharedApplication].delegate;
    [appD.window addSubview:indicatorView];
    [indicatorView.activityView startAnimating];
    appD.window.userInteractionEnabled = NO;
    return indicatorView;
    
}


+(void)stopIndicatorViewAnimating{

    if (indicatorView == nil) {
        indicatorView = [[YIndicatorView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    }
    
    if (indicatorView.activityView.isAnimating) {
        [indicatorView.activityView stopAnimating];
    }
    
    if (indicatorView.delegate && [indicatorView.delegate respondsToSelector:@selector(changeStartViewFlag:)]) {
        [indicatorView.delegate changeStartViewFlag:indicatorView];
    }
    [indicatorView.timer invalidate];
    indicatorView.timer = nil;
    AppDelegate *appD = [UIApplication sharedApplication].delegate;
    appD.window.userInteractionEnabled = YES;
    [indicatorView removeFromSuperview];
    
}
-(void)timerAclick:(NSTimer*)timer
{
    AppDelegate *appD = [UIApplication sharedApplication].delegate;
    appD.window.userInteractionEnabled = YES;

    [self removeFromSuperview];
}

@end









