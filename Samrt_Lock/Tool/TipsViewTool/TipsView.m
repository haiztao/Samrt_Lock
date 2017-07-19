//
//  TipsView.m
//  TodayView
//
//  Created by ADSmartAir on 14/10/31.
//  Copyright (c) 2014年 guzi. All rights reserved.
//

#import "TipsView.h"
#import "AppDelegate.h"

static TipsView *tipsView = nil;
#define YBlack        [UIColor colorWithRed:45.0/255.0 green:45.0/255.0 blue:45.0/255.0 alpha:0.8f]
@implementation TipsView

+(id)getSingleTipsViewWithTipsString:(NSString *)tipsString andRemindTime:(NSTimeInterval)time{
    
    if (tipsString == nil || [tipsString isEqualToString:@""]) {
        return nil;
    }
    CGRect rect = [tipsString boundingRectWithSize:CGSizeMake(200, 9999) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"Arial" size:18]} context:nil];
    CGSize subSize =  rect.size;
    if (tipsView==nil) {
        tipsView = [[TipsView alloc]init];
        tipsView.tipsLabel = [[UILabel alloc]init];
        
        tipsView.tipsLabel.backgroundColor = YBlack;
        tipsView.tipsLabel.textAlignment = NSTextAlignmentCenter;
        tipsView.tipsLabel.textColor = [UIColor whiteColor];
        tipsView.tipsLabel.font = [UIFont fontWithName:@"Arial" size:18];
        tipsView.tipsLabel.numberOfLines = 0;
        tipsView.tipsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    tipsView.tipsLabel.font = [UIFont fontWithName:@"Arial" size:18];
    CGPoint pointA = CGPointMake( (KMainScreenSizeWidth - subSize.width - 20) / 2, KMainScreenSizeHeight / 2);
    tipsView.tipsLabel.frame = CGRectMake(pointA.x+subSize.width+40, pointA.y+subSize.height+20, 20,10);
    tipsView.tipsLabel.layer.masksToBounds = YES;
    tipsView.tipsLabel.layer.cornerRadius = 5;
    
    tipsView.tipsLabel.text = tipsString;

    
    AppDelegate *appd = [UIApplication sharedApplication].delegate;
    [appd.window addSubview:tipsView.tipsLabel];
    //    [target.view addSubview:tipsView.tipsLabel];
    if ( time <= 0.001) {
        time = 3;
    }
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        tipsView.tipsLabel.frame = CGRectMake(pointA.x, pointA.y, subSize.width+20, subSize.height+10);

    } completion:nil];
    
    
    [tipsView.timer invalidate];
    tipsView.timer = [NSTimer scheduledTimerWithTimeInterval:time target:tipsView selector:@selector(doCancleTipsView:) userInfo:nil repeats:NO];

    
    return tipsView;
}

-(void)doCancleTipsView:(NSTimer *)sender{
    [sender invalidate];
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        tipsView.tipsLabel.transform =CGAffineTransformMakeScale(0.5,0.5);
        tipsView.tipsLabel.alpha = 0;
    } completion:^(BOOL finished) {
        [tipsView.tipsLabel removeFromSuperview];
        tipsView.tipsLabel.transform =CGAffineTransformMakeScale(1,1);
        tipsView.tipsLabel.alpha = 1;
    }];
    
}

@end
