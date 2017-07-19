//
//  BLEScanListView.m
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#define KMainScreenSizeWidth [[UIScreen mainScreen] bounds].size.width
#define KMainScreenSizeHeight [[UIScreen mainScreen] bounds].size.height
#define YColorRGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#import "BLEScanListView.h"



@interface BLEScanListView ()<UITableViewDelegate,UITableViewDataSource>

{
    SqliteManager *sqliteManger;
}

@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSArray *dataArray;



@end

@implementation BLEScanListView

-(instancetype)initWithFrame:(CGRect)frame DataArray:(NSArray *)dataArray{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        
        self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(frame.size.width * 0.2, frame.size.height * 0.3, frame.size.width * 0.6, frame.size.height * 0.4) style:UITableViewStyleGrouped];
        [self addSubview:self.tableView];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.backgroundColor = [UIColor whiteColor];
        UILabel *headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, frame.size.width * 0.6, 18)];
        headerLabel.text = NSLocalizedString(@"DeviceList", nil);
        [self.tableView addSubview:headerLabel];
        self.dataArray = dataArray;
    }
    return self;
}
#pragma mark - tableView - DataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *cellID = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }

    NSDictionary *peripheralDict = self.dataArray[indexPath.row];//@{@"Peripheral":peripheral,@"deviceMac":deviceMac};
    CBPeripheral *peripheral = [peripheralDict objectForKey:@"Peripheral"];
    NSString *deviceMac = [peripheralDict objectForKey:@"deviceMac"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@-%@",peripheral.name,deviceMac];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}


#pragma mark - 点击cell方法
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *peripheralDict = self.dataArray[indexPath.row];//@{@"Peripheral":peripheral,@"deviceMac":deviceMac};
    CBPeripheral *peripheral = [peripheralDict objectForKey:@"Peripheral"];
    NSString *deviceMac = [peripheralDict objectForKey:@"deviceMac"];
    NSLog(@"select peripheral - %@",peripheral);
    
    DeviceModel *newDevice = [[DeviceModel alloc]init];
    newDevice.deviceMac = deviceMac;
    newDevice.identifier = peripheral.identifier.UUIDString;
    newDevice.deviceName = peripheral.name;
    newDevice.devicePassword = @"000000";
    sqliteManger = [SqliteManager shareSqliteManager];
    NSMutableArray *dataArray = [sqliteManger getAllDeviceInfo];
    
    BOOL isAddBefore = NO;
    BOOL isNewAndJustAdd = NO;
    if (dataArray.count == 0) {
        [sqliteManger insterDeviceInfo:newDevice];
        isAddBefore = YES;
        isNewAndJustAdd = YES;
    }else{
        for (int i = 0; i < dataArray.count; i ++) {
            DeviceModel *deviceModel = dataArray[i];
            if ([deviceModel.deviceMac isEqualToString:newDevice.deviceMac]) {
                NSLog(@"数据库已添加过");
                isAddBefore = YES;
            }
        }
        if (isAddBefore == NO) {
            [sqliteManger insterDeviceInfo:newDevice];
            isNewAndJustAdd = YES;
        }
    }
    if (isNewAndJustAdd == YES) {
        if (self.selectBlock) {
            self.selectBlock(newDevice);
        }
    }
    
    
    self.superview.userInteractionEnabled = NO;
    [UIView animateWithDuration:1 animations:^{
        
    } completion:^(BOOL finished) {
        self.superview.userInteractionEnabled = YES;
        [self removeFromSuperview];
    }];


}




-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.superview.userInteractionEnabled = NO;
    [UIView animateWithDuration:1 animations:^{
        
    } completion:^(BOOL finished) {
        self.superview.userInteractionEnabled = YES;
        [self removeFromSuperview];
    }];
    
}

@end
