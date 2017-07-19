//
//  WIFIModelViewController.m
//  Samrt_Lock
//
//  Created by haitao on 16/5/18.
//  Copyright © 2016年 haitao. All rights reserved.
//



#define YColorRGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define DeviceIP_Info @"DeviceIP_Info"

#import "WIFIModelViewController.h"
#import "HTDeviceCollectionViewCell.h"
#import <Masonry.h>

#import "WIFiManage.h"
#import "WifiConfigureView.h"
//数据库、model
#import "DeviceModel.h"
#import "SqliteManager.h"
#import "TipsView.h"//提示
#import "WKProgressHUD.h"//提示
#import "YIndicatorView.h"
#import "BLEBaseModel.h"

#import "WIFiManage.h"

static NSString *cellID = @"Wificell";

@interface WIFIModelViewController ()<UITextFieldDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UIActionSheetDelegate,UIAlertViewDelegate,WIFiManageDelegate>

@property (weak, nonatomic) IBOutlet UIView *listView;//列表
@property (weak, nonatomic) IBOutlet UIButton *addDeviceButton;//添加设备
@property (weak, nonatomic) IBOutlet UIButton *openLockButton;//开锁
@property (weak, nonatomic) IBOutlet UILabel *lockStateLabel;//锁状态

@property (weak, nonatomic) IBOutlet UIImageView *pairImageView;
@property (weak, nonatomic) IBOutlet UILabel *pairLockLabel;
@property (nonatomic,strong) NSTimer *connectTimer;//连接计时器

@property (nonatomic,strong) NSTimer *isAutoConnectTimer;//自动连接

@property (nonatomic,strong) NSString *serectString;//通讯秘钥

@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) NSMutableArray *deviceArray;
@property (nonatomic,strong) SqliteManager *sqlManage;
@property (nonatomic,strong) UITextField *textField;
@property (nonatomic,strong) DeviceModel *longPressDevice;
@property (nonatomic,assign) NSInteger longPressRow;

@property (nonatomic,strong) DeviceModel *connectWifiDevice;

@property (nonatomic,strong) WIFiManage *wifiManage;

@property (nonatomic,strong) NSString *deviceMacNew;

@property (nonatomic,strong) WifiConfigureView *configureView;


@end

@implementation WIFIModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setUpTHeUIView];
    
    self.wifiManage = [WIFiManage shareWifiManager];
    
    self.sqlManage = [SqliteManager shareSqliteManager];
    
    [self uploadCollectionViewData];
    
    [self autoConnectTheLastConnectPeripheral];


    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.wifiManage.delegate = self;
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
    
    NSString *lastConnectDeviceMac = [[NSUserDefaults standardUserDefaults] objectForKey:LastConnectWifiDevice];
    if (lastConnectDeviceMac == nil || [lastConnectDeviceMac isEqualToString:@""]) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        for (DeviceModel *device in self.deviceArray) {
            if ([lastConnectDeviceMac isEqualToString:device.deviceMac]) {
                [WKProgressHUD showInView:self.view withText:NSLocalizedString(@"AutoConnecting", nil) animated:YES];
                [self.isAutoConnectTimer invalidate];
                self.isAutoConnectTimer = nil;
                self.isAutoConnectTimer = [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(connectionTimeout) userInfo:nil repeats:NO];
                [self.wifiManage connectDevice:device];
                self.connectWifiDevice = device;
            }
        }
    });
    
}



-(void)setUpTHeUIView{
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self.addDeviceButton setTitle:NSLocalizedString(@"Configure_wifi", nil) forState:UIControlStateNormal];
    [self.openLockButton setTitle:NSLocalizedString(@"Open_Lock", nil) forState:UIControlStateNormal];
    
    self.lockStateLabel.text = NSLocalizedString(@"State_of_the_Lock", nil) ;
    self.pairLockLabel.text = NSLocalizedString(@"未配对", nil);

    self.addDeviceButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.openLockButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.openLockButton.enabled = NO;
    self.lockStateLabel.adjustsFontSizeToFitWidth = YES;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"HTDeviceCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:cellID];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.listView addSubview:self.collectionView];
    // 防止block中的循环引用
    __weak typeof(self) weakSelf = self;
    // 使用mas_makeConstraints添加约束
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.top.equalTo(weakSelf.listView);
        make.left.equalTo(weakSelf.listView);
        make.bottom.equalTo(weakSelf.listView);
        make.right.equalTo(weakSelf.listView);
    }];
}
#pragma mark - 配置WiFi
- (IBAction)configureWifiAndAddDevice:(UIButton *)sender {
    
    self.configureView = [[WifiConfigureView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:_configureView];

    __weak typeof(self) weakSelf = self;
    // 使用mas_makeConstraints添加约束
    [_configureView mas_makeConstraints:^(MASConstraintMaker *make) {
        // 添加大小约束（make就是要添加约束的控件view）
        make.top.equalTo(weakSelf.view);
        make.left.equalTo(weakSelf.view);
        make.bottom.equalTo(weakSelf.view);
        make.right.equalTo(weakSelf.view);
    }];
    _configureView.completeBlock = ^(NSString *deviceMac){
        
        NSArray *dataArray = [weakSelf.sqlManage getAllWifiDeviceInfo];
        
        DeviceModel *newDevice = [[DeviceModel alloc]init];
        newDevice.deviceMac = deviceMac;
        newDevice.deviceName = @"LOCK";
        newDevice.devicePassword = @"000000";
        
        BOOL isAddBefore = NO;
        BOOL isNewAndJustAdd = NO;
        if (dataArray.count == 0) {
            [weakSelf.sqlManage insterWifiDeviceInfo:newDevice];
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
                [weakSelf.sqlManage insterWifiDeviceInfo:newDevice];
                isNewAndJustAdd = YES;
            }
        }
        
        if (isNewAndJustAdd == YES) {
            [weakSelf uploadCollectionViewData];
        }
    };
    
}

#pragma mark - 获取添加过的设备
-(void) uploadCollectionViewData {
    NSArray *dataArray = [self.sqlManage getAllWifiDeviceInfo];
    self.deviceArray = [NSMutableArray arrayWithArray:dataArray];
    
    [self.collectionView reloadData];
}

#pragma mark - 设备列表
-(UICollectionView *)collectionView{
    if (!_collectionView) {
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        float width = self.listView.frame.size.height - 50 ;
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
#pragma mark - 设备列表
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.deviceArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    HTDeviceCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    DeviceModel *wifiDevice = self.deviceArray[indexPath.row];
    
    cell.deviceNameLabel.text = wifiDevice.deviceName;
    
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpress:)];
    [cell addGestureRecognizer:longPress];
    
    return cell;
}
#pragma mark - 连接设备
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"select And Connect");
    [WKProgressHUD showInView:self.view withText:NSLocalizedString(@"Connecting", nil) animated:YES];
    [self.connectTimer invalidate];
    self.connectTimer = nil;
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(connectionTimeout) userInfo:nil repeats:NO];
    self.connectWifiDevice = self.deviceArray[indexPath.row];
    
    [self.wifiManage connectDevice:self.connectWifiDevice];
}

#pragma mark - 连接成功
-(void)connectDeviceSuccessfully{

    [self.isAutoConnectTimer invalidate];
    self.isAutoConnectTimer = nil;
    [self.connectTimer invalidate];
    self.connectTimer = nil;
    self.openLockButton.enabled = YES;
    [WKProgressHUD dismissInView:self.view animated:YES];
    [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"connect_Successfully", nil) andRemindTime:2];
    self.pairLockLabel.text = [NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"配对", nil),self.connectWifiDevice.deviceName];

}
#pragma mark - 设备断开
-(void)wifiDeviceIsDisconnected{
    
    self.pairLockLabel.text = NSLocalizedString(@"未配对", nil);
    self.openLockButton.enabled = NO;
    self.lockStateLabel.text = NSLocalizedString(@"State_of_the_Lock", nil);
}


#pragma mark -超时
-(void)connectionTimeout{
    
    [self.connectTimer invalidate];
    [self.isAutoConnectTimer invalidate];
    self.connectTimer = nil;
    self.isAutoConnectTimer = nil;
    [WKProgressHUD dismissInView:self.view animated:YES];
    [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"wifi连接失败", nil) andRemindTime:2];
 
}

- (IBAction)openDoorLock:(UIButton *)sender {
    [self.wifiManage openTheLockInstruction];
    sender.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
    });
}


-(void)showTheLockState:(BOOL)islock{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //连接上了
        if (islock == YES) {
            self.lockStateLabel.text =  NSLocalizedString(@"Locked_Lock", nil) ;
            self.openLockButton.enabled = YES;
        }else{
            self.lockStateLabel.text =  NSLocalizedString(@"Lock_Opened", nil);
//            self.openLockButton.enabled = NO;
        }
        
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
            
            [self.sqlManage deleteWifiDeviceInfo:self.longPressDevice];
            [self uploadCollectionViewData];
            if ([self.longPressDevice.deviceMac isEqualToString:self.connectWifiDevice.deviceMac]) {
                [self.wifiManage disconnectWifiDevice];
                self.pairLockLabel.text = NSLocalizedString(@"未配对", nil);
                self.openLockButton.enabled = NO;
                self.lockStateLabel.text = NSLocalizedString(@"State_of_the_Lock", nil);
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
                [self.sqlManage updateWifiDeviceInfo:self.longPressDevice];
                [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"修改成功", nil) andRemindTime:2];
                [self uploadCollectionViewData];
                if ([self.longPressDevice.deviceMac isEqualToString:self.connectWifiDevice.deviceMac]) {
                    self.pairLockLabel.text = [NSString stringWithFormat:@"%@:%@",NSLocalizedString(@"配对", nil),self.connectWifiDevice.deviceName];
                }
            }
            
        }else if (alertView.tag == 200){
            
            NSLog(@"长按输入的密码 %@",_textField.text);
            if (_textField.text.length != 6 ) {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"请输入六位密码", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }else {
#pragma mark - 修改通讯密码
                
                [self.wifiManage changeCurrentDevicePassword:self.connectWifiDevice AndNewPassword:_textField.text];
            }
        }else if (alertView.tag == 300){
            NSLog(@"长按输入的密码 %@",_textField.text);
            if (_textField.text.length != 6 ) {
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"请输入六位密码", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }else {
                //确定是数字才保存数据库
                [self changeDevicePasswordSucceed];
                
            }
        }
    }else if (buttonIndex == 0){
        if (alertView.tag == 500){//成功
            if (buttonIndex == 0) {
                
                
                [UIView animateWithDuration:1 animations:^{
                    
                } completion:^(BOOL finished) {
                    self.view.userInteractionEnabled = YES;
                    [self.configureView removeFromSuperview];
                }];
            }
        }
    }
    
}

#pragma mark - changePassword修改数据库密码
-(void)changeDevicePasswordSucceed{
    NSLog(@"修改数据库密码");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.longPressDevice.devicePassword = _textField.text;
        [self.sqlManage updateWifiDeviceInfo:self.longPressDevice];
        [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"修改成功", nil) andRemindTime:2];
    });

}

#pragma mark - 密码错误
-(void)receiveInformationDueToTHeWrongPassword{
     dispatch_async(dispatch_get_main_queue(), ^{
         [TipsView getSingleTipsViewWithTipsString:NSLocalizedString(@"通讯密码有误", nil) andRemindTime:2];
     });
}


-(NSMutableArray *)deviceArray{
    if (_deviceArray == nil) {
        _deviceArray = [[NSMutableArray alloc]init];
    }
    return _deviceArray;
}



#pragma mark - 配置成功代理
-(void)configureSucceedWithDeviceMac:(NSString *)deviceMac{
    
    [self stopIndicatorAnimating];
    [self equipmentIsAddedToTheDatabaseWithDeviceMac:deviceMac];
    
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"配置成功", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil, nil];
    alert.tag = 500;
    [alert show];
    
}
#pragma mark - 配置失败
-(void) configureFailWithTipString:(NSString *)tipString{
    [self stopIndicatorAnimating];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"配置失败", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"确定", nil) otherButtonTitles:nil, nil];
        [alertView show];
    });

}
#pragma mark - 添加设备
-(void) equipmentIsAddedToTheDatabaseWithDeviceMac:(NSString *)deviceMac{
    
    NSArray *dataArray = [self.sqlManage getAllWifiDeviceInfo];
    DeviceModel *newDevice = [[DeviceModel alloc]init];
    newDevice.deviceMac = deviceMac;
    newDevice.deviceName = @"Lock";
    newDevice.devicePassword = @"000000";
    BOOL isAddBefore = NO;
    BOOL isNewAndJustAdd = NO;
    if (dataArray.count == 0) {
        [self.sqlManage insterWifiDeviceInfo:newDevice];
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
            [self.sqlManage insterWifiDeviceInfo:newDevice];
            isNewAndJustAdd = YES;
        }
    }
    if (isNewAndJustAdd == YES) {
        [self uploadCollectionViewData];
    }
}


-(void)stopIndicatorAnimating{
    dispatch_async(dispatch_get_main_queue(), ^{
        [YIndicatorView stopIndicatorViewAnimating];
    });
}



@end
