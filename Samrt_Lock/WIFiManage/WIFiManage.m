//
//  WIFiManage.m
//  Samrt_Lock
//
//  Created by haitao on 16/7/14.
//  Copyright © 2016年 haitao. All rights reserved.
//




#import "WIFiManage.h"

#import "smartlinklib_7x.h"
#import "HFSmartLink.h"
#import "HFSmartLinkDeviceInfo.h"
#import <SystemConfiguration/CaptiveNetwork.h>

//tcp/udp
#import "AsyncUdpSocket.h"
#import "AsyncSocket.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "WifiManager.h"

//128位加密
#import "NSData+SY_AES.h"



@interface WIFiManage ()
{
    HFSmartLink * smtlk;
    BOOL isconnecting;
}
@property (strong, nonatomic)  NSString *wifiText;

@property (strong, nonatomic)  NSString *passwordText;

//@property (nonatomic,strong) NSString *deviceMac;

@property (nonatomic,strong) NSString *deviceIP;

@property (nonatomic,strong) NSString *serectString;

@property (nonatomic,strong)  AsyncUdpSocket *asyncUdpSocket;

@property (nonatomic,strong) AsyncSocket *socket;

@property (nonatomic,strong) NSString *broadcast;

@property (nonatomic,strong) NSTimer *timer;

@property (nonatomic,assign) NSInteger timerCount;//计数器

@property (nonatomic,strong) NSTimer *heartbeatTimer;//心跳包

@property (nonatomic,strong) NSTimer *readTimer;//读取数据

@property (nonatomic,strong) DeviceModel *connectWifiDevice;

@property (nonatomic,assign) NSInteger heartbeatCount;


@end


@implementation WIFiManage

static WIFiManage * wifiManager = nil;

+ (instancetype)shareWifiManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wifiManager = [[WIFiManage alloc]init];
    });
    return wifiManager;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        
        smtlk = [HFSmartLink shareInstence];
        smtlk.isConfigOneDevice = true;
        smtlk.waitTimers = 30;
        isconnecting = false;
        
        //密钥
        Byte byte[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
        NSData *adata = [[NSData alloc] initWithBytes:byte length:16];
        self.serectString = [[NSString alloc] initWithData:adata encoding:NSUTF8StringEncoding];
        
        _socket = [[AsyncSocket alloc] initWithDelegate:self];
        [self.readTimer invalidate];
        self.readTimer = nil;
        self.readTimer =  [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(readDataWfi) userInfo:nil repeats:YES];
        
        self.heartbeatCount = 0;
 
    }
    return self;
}

-(void)disconnectWifiDevice{
    [self.socket disconnect];
}

#pragma mark - 读取UDP广播信息
-(void) readDataWfi{
    [_socket readDataWithTimeout:-1 tag:0];
}

#pragma mark - 配置WiFi
- (void)configureWiFiWithwifiName:(NSString *)wifiName Password:(NSString *)pswdStr{

    NSLog(@"wifiName: %@ -|- pswdStr: %@",wifiName,pswdStr);
    
    if(!isconnecting){
        isconnecting = true;
        [smtlk startWithSSID:wifiName Key:pswdStr withV3x:true
                processblock: ^(NSInteger pro) {
                    NSLog(@"进度：%ld",(long)pro);
                } successBlock:^(HFSmartLinkDeviceInfo *dev) {

#pragma mark - ip获取的方法
                    NSLog(@"dev.mac:%@,dev.ip:%@",dev.mac,dev.ip);

                    
                    NSLog(@"Configure Succeed");
                    if ([self.delegate respondsToSelector:@selector(configureSucceedWithDeviceMac:)]) {
                        [self.delegate configureSucceedWithDeviceMac:dev.mac];
                    }
                    
                } failBlock:^(NSString *failmsg) {

                    NSLog(@"failmsg :%@",failmsg);
                    if ([self.delegate respondsToSelector:@selector(configureFailWithTipString:)]) {
                         [self.delegate configureFailWithTipString:failmsg];
                    }
                   
                    
                } endBlock:^(NSDictionary *deviceDic) {

                    isconnecting  = false;
                    
                }];
        
    }else{
        
        [smtlk stopWithBlock:^(NSString *stopMsg, BOOL isOk) {

            NSLog(@" stopMsg %@ ",stopMsg);
            
        }];
    }
    
    
    
}


#pragma mark - udp连接
-(void)connectDevice:(DeviceModel *)device{
    
    self.connectWifiDevice = device;
    //udp广播
    _asyncUdpSocket = [[AsyncUdpSocket alloc]initWithDelegate:self];
    NSError *err = nil;
    [_asyncUdpSocket enableBroadcast:YES error:&err];
    [_asyncUdpSocket bindToPort:48899 error:&err];
    
    WifiManager * manager = [[WifiManager alloc ] init];
    NSDictionary * wifiInfor = [manager getWifiInformation];
    
    _broadcast = [wifiInfor objectForKey:WifiBroadcastAddress];
    
    NSLog(@"网关=%@ 广播地址%@ 子网掩码%@ 接口=%@ 本机ip:%@",(NSString *)[wifiInfor objectForKey:WifiGateWay],(NSString *)[wifiInfor objectForKey:WifiBroadcastAddress],(NSString *)[wifiInfor objectForKey:WifiNetMast],(NSString *)[wifiInfor objectForKey:WifiInterface],(NSString *)[wifiInfor objectForKey:WifiIP]);
    
    self.timerCount = 0;
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(getTheWIFIMac) userInfo:nil repeats:YES];
    
    
}

#pragma mark - 获取设备广播地址
-(void)getTheWIFIMac{
    
    self.timerCount += 1;
    NSLog(@"次数 %ld",(long)self.timerCount);
    NSString *str = @"HF-A11ASSISTHREAD";
    int port = 48899;
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [_asyncUdpSocket sendData:data toHost:_broadcast port:port withTimeout:-1 tag:0];
    
    if (self.timerCount > 3) {
        [self.timer invalidate];
        self.timer = nil;
    }
}


#pragma mark - udp代理方法
-(BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    
    NSLog(@"data=%@",data);
    NSLog(@"host=%@ 端口=%d",host,port);
    NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"string=%@  4",string);
    
    if ([string rangeOfString:self.connectWifiDevice.deviceMac].location != NSNotFound) {
        
        NSArray *strArray = [string componentsSeparatedByString:@","];
        NSString *host = strArray[0];
        NSLog(@"现在host : %@",host);
        [self.timer invalidate];
        self.timer = nil;
        self.deviceIP = host;
        [self connectDeviceWithDeviceIP:host];
        
    }else{
        
        NSLog(@"nofound");
    }
    
    [_asyncUdpSocket receiveWithTimeout:-1 tag:0];   //服务器端启动线程接收
    
    return YES;
}

-(void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error
{
    
    NSLog(@"没有接到消息");
}

-(void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    
    NSLog(@"已经发送消息");
    
    [_asyncUdpSocket receiveWithTimeout:-1 tag:0];   //服务器端启动线程接收
}

-(void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    
    NSLog(@"没有发送消息");
}

-(void)onUdpSocketDidClose:(AsyncUdpSocket *)sock
{
    
    NSLog(@"断开连接");
    
}


#pragma mark - 连接成功与否
- (void)connectDeviceWithDeviceIP:(NSString *)deviceIP {
    
    [_socket disconnect];
    
    NSLog(@"_deviceIP:%@ ",deviceIP);
    
    NSError *error = nil;
    if (![_socket connectToHost:deviceIP onPort:8899 error:&error]) {
        
        NSLog(@"Could't_Connect error:%@",error);

    } else {
        
        NSLog(@"connect_Successfully");
        
        [self sendConnectStateAndshakeHand];
        
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
        self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(sendHeartbeatPackets) userInfo:nil repeats:YES];
        
        [[NSUserDefaults standardUserDefaults] setObject:self.connectWifiDevice.deviceMac forKey:LastConnectWifiDevice];
        if ([self.delegate respondsToSelector:@selector(connectDeviceSuccessfully)]) {
            [self.delegate connectDeviceSuccessfully];
        }
        

    }
    
}

#pragma mark - tcp代理
//发送成功回调
-(void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    
//    NSLog(@"发送成功 ");
    
}
#pragma mark - 处理返回信息
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    [self dealWithWIFIData:data];
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    NSLog(@"sock %@ -- %ld",sock,(unsigned long)partialLength);
}

- (void)dealWithWIFIData:(NSData *)bleData{
    
    self.heartbeatCount = 0;
    
    NSData *unLockData = [bleData AES128DecryptWithKey:self.serectString];
    NSLog(@"接收解密: %@",unLockData);
    
    uint8_t dataVal[16] = {0x0};
    [unLockData getBytes:&dataVal length:unLockData.length];
    
    if ( bleData.length < 1 ) {
        NSLog(@"收到 bleData %@    dataVal %zi",unLockData,dataVal[0]);
        return;
    }
    
    BOOL islock = NO;
    
    switch (dataVal[2]) {
        case 0x00://握手查询
        {

            if (dataVal[3] == 0x00) {
                NSLog(@"未上锁状态");
                islock = NO;
            }else{
                NSLog(@"上锁状态");
                islock = YES;
            }
            if ([self.delegate respondsToSelector:@selector(showTheLockState:)]) {
                [self.delegate showTheLockState:islock];
            }

            break;
        }
            
        case 0x01: //锁状态改变时自动回复
        {
            
            if (dataVal[3] == 0x00) {
                NSLog(@"未上锁");
                islock = NO;
            }else{
                NSLog(@"上锁");
                islock = YES;
            }
            if ([self.delegate respondsToSelector:@selector(showTheLockState:)]) {
                [self.delegate showTheLockState:islock];
            }
            break;
        }
        case 0x02:
        {
            
            if (dataVal[3] == 0x00) {
                NSLog(@"控制开锁");
                islock = NO;
            }else{
                NSLog(@"控制-上锁");
                islock = YES;
            }
            if ([self.delegate respondsToSelector:@selector(showTheLockState:)]) {
                [self.delegate showTheLockState:islock];
            }

            break;
        }
        case 0x03:
        {
            
            if (dataVal[3] == 0x01 ) {
                NSLog(@"修改成功");
                if ([self.delegate respondsToSelector:@selector(changeDevicePasswordSucceed)]) {
                     [self.delegate changeDevicePasswordSucceed];
                }
            }
            
            break;
        }
        case 0x04:
        {
            NSLog(@"心跳");
           
            break;
        }
        case 0xfe:
        {
            NSLog(@"指令错误");
            if ([self.delegate respondsToSelector:@selector(receiveInformationDueToTHeWrongPassword)]) {
                [self.delegate receiveInformationDueToTHeWrongPassword];
            }
            
            break;
        }
            
        default:
            break;
            
    }
    
}

#pragma mark - 发送心跳包
-(void) sendHeartbeatPackets{
    
    [self writeDataToDeviceSendInstructions:HeartBeat];
    self.heartbeatCount += 1;
    
    NSLog(@"heartbeatCount %ld",(long)self.heartbeatCount);
    if (self.heartbeatCount > 2) {
        NSLog(@"heartbeatCount %ld  %@",(long)self.heartbeatCount,self.delegate);
        if ([self.delegate respondsToSelector:@selector(wifiDeviceIsDisconnected)]) {
            [self.delegate wifiDeviceIsDisconnected];
        }
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
}


#pragma mark -- 发送wifi连接指令
-(void)sendConnectStateAndshakeHand{
    [self writeDataToDeviceSendInstructions:ShakeHand];
}

#pragma mark - 开锁
- (void)openTheLockInstruction {
    [self writeDataToDeviceSendInstructions:OpenLock];
}
#pragma mark - 查询状态
-(void)queryLockStateInstruction{
    [self writeDataToDeviceSendInstructions:LockState];
}


-(void) writeDataToDeviceSendInstructions:(SendInstructions)sendInstructions {
    
    if (_socket == nil) {
        _socket = [[AsyncSocket alloc] initWithDelegate:self];
    }
    
    UInt8 SendData[20] = {0x0};
    NSInteger dataLength = 0;
    NSData *sendData = nil;
    
    NSString *key1 = [self.connectWifiDevice.devicePassword substringWithRange:NSMakeRange(0, 2)];
    NSString *key2 = [self.connectWifiDevice.devicePassword substringWithRange:NSMakeRange(2, 2)];
    NSString *key3 = [self.connectWifiDevice.devicePassword substringWithRange:NSMakeRange(4, 2)];
    
    switch (sendInstructions) {
        case ShakeHand:
        {
            SendData[0] = 0x55;
            SendData[1] = 0x10;
            
            SendData[2] = 0x00;
            SendData[3] = 0x00;
            break;
        }
        case LockState:
        {

            SendData[0] = 0x55;
            SendData[1] = 0x10;
            
            SendData[2] = 0x01;
            SendData[3] = 0x00;
            break;
        }
        case OpenLock:
        {
            
            SendData[0] = 0x55;
            SendData[1] = 0x10;
            
            SendData[2] = 0x02;
            SendData[3] = 0x01;
            break;
        }
        case HeartBeat:
        {
            SendData[0] = 0x55;
            SendData[1] = 0x10;
            
            SendData[2] = 0x04;
            SendData[3] = 0x00;
            break;
        }
            
            
        default:
            break;
    }
    
    SendData[4] = 0x00;
    SendData[5] = 0x00;
    SendData[6] = 0x00;
    
    SendData[7] = 0x00;
    SendData[8] = 0x00;
    SendData[9] = 0x00;
    
    SendData[10] = 0x00;
    SendData[11] = 0x00;
    
    SendData[12] = [key1 intValue];
    SendData[13] = [key2 intValue];
    SendData[14] = [key3 intValue];
    SendData[15] = 0xAA;
    
    dataLength = 16;
    
    
    sendData = [NSData dataWithBytes:SendData length:dataLength];
    NSLog(@"发送指令: %@",sendData);
    NSData *sendSerectData = [sendData AES128EncryptWithKey:self.serectString];
    [_socket writeData:sendSerectData withTimeout:-1 tag:2];
    [_socket readDataWithTimeout:-1 tag:2];
}

#pragma mark - 修改密码
#pragma mark - 修改密码
-(void)changeCurrentDevicePassword:(DeviceModel *)currentDevice AndNewPassword:(NSString *)newPassword{
    
    UInt8 SendData[20] = {0x0};
    NSInteger dataLength = 0;
    NSData *sendData = nil;
    
    NSString *newKey1 = [newPassword substringWithRange:NSMakeRange(0, 2)];
    NSString *newKey2 = [newPassword substringWithRange:NSMakeRange(2, 2)];
    NSString *newKey3 = [newPassword substringWithRange:NSMakeRange(4, 2)];
    
    NSLog(@"连接的device %@",currentDevice);
    
    NSString *key1 = [currentDevice.devicePassword substringWithRange:NSMakeRange(0, 2)];
    NSString *key2 = [currentDevice.devicePassword substringWithRange:NSMakeRange(2, 2)];
    NSString *key3 = [currentDevice.devicePassword substringWithRange:NSMakeRange(4, 2)];
    
    SendData[0] = 0x55;
    SendData[1] = 0x10;
    SendData[2] = 0x03;
    
    SendData[3] = [newKey1 intValue];
    SendData[4] = [newKey2 intValue];
    SendData[5] = [newKey3 intValue];
    
    SendData[6] = 0x00;
    SendData[7] = 0x00;
    SendData[8] = 0x00;
    SendData[9] = 0x00;
    
    SendData[10] = 0x00;
    SendData[11] = 0x00;
    
    SendData[12] = [key1 intValue];
    SendData[13] = [key2 intValue];
    SendData[14] = [key3 intValue];
    SendData[15] = 0xAA;
    
    dataLength = 16;
    
    sendData = [NSData dataWithBytes:SendData length:dataLength];
    NSLog(@"发送修改密码: %@",sendData);
    NSData *sendSerectData = [sendData AES128EncryptWithKey:self.serectString];
    [_socket writeData:sendSerectData withTimeout:-1 tag:2];
    [_socket readDataWithTimeout:-1 tag:2];
    
}




@end
