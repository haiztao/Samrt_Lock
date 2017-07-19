//
//  BLEModelViewController.m
//  Samrt_Lock
//
//  Created by haitao on 16/5/18.
//  Copyright © 2016年 haitao. All rights reserved.
//

#define YColorRGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]


#import "BLEModelViewController.h"
#import "HTDeviceCollectionViewCell.h"
#import <Masonry.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEBaseModel.h"
#import "BLEManage.h"
#import "BLEScanListView.h"
#import "SqliteManager.h"
#import "DeviceModel.h"
#import "TipsView.h"//提示
#import "WKProgressHUD.h"//提示


static NSString *cellID = @"cell";

@interface BLEModelViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,BLEManageDelegate,UIActionSheetDelegate,UIAlertViewDelegate>



@property (nonatomic,strong) UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UIView *bleListView;
@property (weak, nonatomic) IBOutlet UIButton *searchSevice;

@property (weak, nonatomic) IBOutlet UIButton *openLockButton;

@property (weak, nonatomic) IBOutlet UIImageView *pairImageView;
@property (weak, nonatomic) IBOutlet UILabel *pairLockLabel;

@property (weak, nonatomic) IBOutlet UILabel *lockStateLabel;

@property (nonatomic,strong) NSMutableArray *deviceArray;

@property (nonatomic,strong) BLEManage *bleManager;

@property (nonatomic,strong) BLEScanListView *scanListView;

@property (nonatomic,strong) SqliteManager *sqlManage;

@property (nonatomic,assign) NSInteger longPressRow;

@property (nonatomic,strong) UITextField *textField;

@property (nonatomic,strong) DeviceModel *longPressDevice;

@property (nonatomic,strong) DeviceModel *currentConnectDevice;

@property (nonatomic,strong) NSTimer *connectTimer;

@property (nonatomic,strong) NSTimer *isAutoConnectTimer;

@end

@implementation BLEModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.searchSevice setTitle:NSLocalizedString(@"Search_Device", nil) forState:UIControlStateNormal];
    [self.openLockButton setTitle:NSLocalizedString(@"Open_Lock", nil) forState:UIControlStateNormal];
    self.openLockButton.enabled = NO;
    self.lockStateLabel.text = NSLocalizedString(@"State_of_the_Lock", nil);
    self.pairLockLabel.text = NSLocalizedString(@"未配对", nil);

    [self.collectionView registerNib:[UINib nibWithNibName:@"HTDeviceCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:cellID];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.bleListView addSubview:self.collectionView];
    // 防止block中的循环引用
    __weak typeof(self) weakSelf = self;
    // 使用mas_makeConstraints添加约束
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.top.equalTo(weakSelf.bleListView);
        make.left.equalTo(weakSelf.bleListView);
        make.bottom.equalTo(weakSelf.bleListView);
        make.right.equalTo(weakSelf.bleListView);
    }];
    

    self.sqlManage = [SqliteManager shareSqliteManager];
    self.bleManager = [BLEManage shareBLEManager];

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self autoConnectTheLastConnectPeripheral];
    });

    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.bleManager.delegate = self;
    [self.bleManager startScanBLEDeviceWithAutoScan:YES];
}

-(void)viewDidDisappear:(BOOL)animated {
    
    [self.isAutoConnectTimer invalidate];
    self.isAutoConnectTimer = nil;
    [self.connectTimer invalidate];
    self.connectTimer = nil;
    [WKProgressHUD dismissInView:self.view animated:YES];
    
}

#pragma mark - 自动连接最后一个连接过的设备
- (void)autoConnectTheLastConnectPeripheral{
    
    NSString *deviceIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:LastConnectDevice];
    
    if (deviceIdentifier == nil || [deviceIdentifier isEqualToString:@""]) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        for (DeviceModel *device in self.deviceArray) {
            if ([deviceIdentifier isEqualToString:device.identifier]) {
                NSLog(@"匹配的 --- %@",device.deviceMac);
                [WKProgressHUD showInView:self.view withText:NSLocalizedString(@"AutoConnecting", nil) animated:YES];
                [self.isAutoConnectTimer invalidate];
                self.isAutoConnectTimer = nil;
                self.isAutoConnectTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(donotConnectAnyDevice) userInfo:nil repeats:NO];
                [self.bleManager connectPeripheral:device];
                self.currentConnectDevice = device;
            }
        }
    });
    
    

}



#pragma mark - 视图出现前加载设备
-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    //取出数据库添加过的设备
    [self uploadCollectionViewData];
}

#pragma mark - 获取添加过的设备
-(void) uploadCollectionViewData {
    NSArray *dataArray = [self.sqlManage getAllDeviceInfo];
    self.deviceArray = [NSMutableArray arrayWithArray:dataArray];
    [self.collectionView reloadData];
}



#pragma mark - 蓝牙代理
-(void)showScanPeripheralArray:(NSMutableArray *)dataArray{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.scanListView removeFromSuperview];
        self.scanListView = [[BLEScanListView alloc]initWithFrame:self.view.frame DataArray:dataArray];
        [self.view addSubview:_scanListView];
        
        __weak typeof(self) weakSelf = self;
        // 使用mas_makeConstraints添加约束
        [self.scanListView mas_makeConstraints:^(MASConstraintMaker *make) {
            // 添加大小约束（make就是要添加约束的控件view）
            make.top.equalTo(weakSelf.view);
            make.left.equalTo(weakSelf.view);
            make.bottom.equalTo(weakSelf.view);
            make.right.equalTo(weakSelf.view);
        }];
        
        _scanListView.selectBlock = ^(DeviceModel *newDevice){
            
            [weakSelf uploadCollectionViewData];
        };
        
    });


    
}


#pragma mark - 锁状态更改界面
-(void)showTheLockState:(BOOL)islock{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (islock == YES) {
            self.lockStateLabel.text =  NSLocalizedString(@"Locked_Lock", nil) ;
            self.openLockButton.enabled = YES;
        }else{
            self.lockStateLabel.text =  NSLocalizedString(@"Lock_Opened", nil);
//            self.openLockButton.enabled = NO;
        }
        
    });
    
    
}

#pragma mark - 搜索蓝牙
- (IBAction)searchBLEDevice:(UIButton *)sender {
    
    [self.bleManager.scanPeripheralArray removeAllObjects];
    [self.bleManager startScanBLEDeviceWithAutoScan:NO];

}



#pragma mark - 开锁指令
- (IBAction)openTheLock:(UIButton *)sender {
    [self.bleManager writeDataToDeviceSendInstructions:OpenLock];
    sender.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
    });
}

-(UICollectionView *)collectionView{
    if (!_collectionView) {

        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        float width = self.bleListView.frame.size.height - 50 ;
        flowLayout.itemSize = CGSizeMake(width , width);
        flowLayout.minimumInteritemSpacing = 25;
        flowLayout.minimumLineSpacing = 25;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    }
    return _collectionView;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.deviceArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    HTDeviceCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    DeviceModel *deviceInfo =  self.deviceArray[indexPath.row];
    
    cell.deviceNameLabel.text = deviceInfo.deviceName;
    
//    UIView *view = [[UIView alloc]initWithFrame:cell.frame];
//    view.backgroundColor = YColorRGB(0xf0, 0xf0, 0xf0);
//    cell.selectedBackgroundView = view;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpress:)];
    [cell addGestureRecognizer:longPress];
    
    return cell;
}
#pragma mark - 选中连接
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    [WKProgressHUD showInView:self.view withText:NSLocalizedString(@"Connecting", nil) animated:YES];
    self.currentConnectDevice = self.deviceArray[indexPath.row];
    [self.bleManager connectPeripheral:self.currentConnectDevice];
    [self.connectTimer invalidate];
    self.connectTimer = nil;
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(donotConnectAnyDevice) userInfo:nil repeats:NO];
    
}
#pragma mark -超时
-(void)donotConnectAnyDevice {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.connectTimer invalidate];
        [self.isAutoConnectTimer invalidate];
        self.connectTimer = nil;
        self.isAutoConnectTimer = nil;
        [WKProgressHUD dismissInView:self.view animated:YES];
        [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"DisConnectAnyDevice", nil) andRemindTime:2];
    });
        
}
#pragma mark - longPress 长按

-(void)longpress:(UILongPressGestureRecognizer *)recognizer{
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        NSLog(@"开始长按手势！");
        HTDeviceCollectionViewCell *cell = (HTDeviceCollectionViewCell *)[recognizer view];
        NSIndexPath  *indexPath = [self.collectionView indexPathForCell:cell];

        self.longPressRow = indexPath.row;
        
        UIActionSheet* mySheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                  destructiveButtonTitle:NSLocalizedString(@"删除设备", nil)
                                  otherButtonTitles:NSLocalizedString(@"修改别名", nil),NSLocalizedString(@"修改设备密码", nil),NSLocalizedString(@"修改本地密码",nil), nil];
        [mySheet showInView:self.view];
    }
    
}

#pragma mark - actionSheet点击响应
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"actionSheet %ld",(long)buttonIndex);
    
    self.longPressDevice = self.deviceArray[self.longPressRow];
    
    switch (buttonIndex) {
        case 0://删除
        {
            [self.sqlManage deleteDeviceInfo:self.longPressDevice];
            [self uploadCollectionViewData];
            
            if ([self.longPressDevice.deviceMac isEqualToString:self.currentConnectDevice.deviceMac]) {
                [self.bleManager disconnectBLEDevice];
                self.pairLockLabel.text = NSLocalizedString(@"未配对", nil);
                self.openLockButton.enabled = NO;
                self.lockStateLabel.text = NSLocalizedString(@"State_of_the_Lock", nil);
            }
            
            NSString *deviceIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:LastConnectDevice];
            if (deviceIdentifier == nil || [deviceIdentifier isEqualToString:@""]) {
                return;
            }
            else if ([deviceIdentifier isEqualToString:self.longPressDevice.identifier]){
                [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:LastConnectDevice];
            }
            
            break;
        }
        case 1://修改别名
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"请输入别名", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                                      otherButtonTitles:NSLocalizedString(@"确定", nil),nil];
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            self.textField = [alertView textFieldAtIndex:0];
            alertView.tag = 100;
            [alertView show];
            
            break;
        }
        case 2://修改密码
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"请输入密码", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                                      otherButtonTitles:NSLocalizedString(@"确定", nil),nil];
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            self.textField = [alertView textFieldAtIndex:0];
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            alertView.tag = 200;
            [alertView show];
            
            break;
        }
        case 3://修改本地密码
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"修改本地密码", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"取消", nil)
                                                      otherButtonTitles:NSLocalizedString(@"确定", nil),nil];
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            self.textField = [alertView textFieldAtIndex:0];
            self.textField.keyboardType = UIKeyboardTypeNumberPad;
            alertView.tag = 300;
            [alertView show];
            
            break;
        }
            
        default:
            break;
    }
    

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        if (alertView.tag == 100) {
            
            if (_textField.text == nil || [_textField.text isEqualToString:@""] ) {
                return;
            }else {
                
                self.longPressDevice.deviceName = _textField.text;
                [self.sqlManage updateDeviceInfo:self.longPressDevice];
                [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"修改成功", nil) andRemindTime:2];
                [self uploadCollectionViewData];
                if ([self.longPressDevice.deviceMac isEqualToString:self.currentConnectDevice.deviceMac]) {
                    self.pairLockLabel.text = [NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"配对", nil),self.currentConnectDevice.deviceName];
                }
            }
            
        }else if (alertView.tag == 200){

            NSLog(@"长按输入的密码 %@",_textField.text);
            if (_textField.text.length != 6 ) {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"请输入六位密码", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }else {
                //确定是数字才保存数据库
                
                [self.bleManager changeCurrentDevicePassword:self.currentConnectDevice AndNewPassword:_textField.text];
            }
            
        }else if (alertView.tag == 300){
            NSLog(@"长按输入的密码 %@",_textField.text);
            if (_textField.text.length != 6) {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"请输入六位密码", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }else {
                //确定是数字才保存数据库
                [self changeDevicePasswordSucceed];
                
            }
        }
    }

}

#pragma mark - 修改成功
-(void)changeDevicePasswordSucceed{
    NSLog(@"修改数据库密码");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.longPressDevice.devicePassword = _textField.text;
        [self.sqlManage updateDeviceInfo:self.longPressDevice];
        [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"修改成功", nil) andRemindTime:2];
    });

}
#pragma mark - 错误密码返回
-(void)receiveInformationDueToTHeWrongPassword{
    dispatch_async(dispatch_get_main_queue(), ^{
        [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"通讯密码有误", nil) andRemindTime:2];
    });

}
#pragma mark - 连接权限
-(void)haveNoPermissionsToConnectDevice{
    dispatch_async(dispatch_get_main_queue(), ^{
        [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"没有连接权限", nil) andRemindTime:2];
    });
}

#pragma mark - 连接成功
-(void)connectDeviceSuccessfully{
    
    [self.isAutoConnectTimer invalidate];
    self.isAutoConnectTimer = nil;
    [self.connectTimer invalidate];
    self.connectTimer = nil;
    
   
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.openLockButton.enabled = YES;
        
        [WKProgressHUD dismissInView:self.view animated:YES];
        [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"connect_Successfully", nil) andRemindTime:2];
        self.pairLockLabel.text = [NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"配对", nil),self.currentConnectDevice.deviceName];
    });
}
#pragma mark -断开连接
-(void)didDisconnectDevice:(DeviceModel *)device{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.openLockButton.enabled = NO;
        self.pairLockLabel.text = NSLocalizedString(@"未配对", nil);
        self.lockStateLabel.text = NSLocalizedString(@"State_of_the_Lock", nil);
    });
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSMutableArray *)deviceArray{
    if (_deviceArray == nil) {
        _deviceArray = [[NSMutableArray alloc]init];
    }
    return _deviceArray;
}



@end
