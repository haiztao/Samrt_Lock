//
//  BLEManage.m
//  智能鞋
//
//  Created by haitao on 16/4/6.
//  Copyright © 2016年 haitao. All rights reserved.
//

#define timeoutSec_updateArray 5
#define timeoutSec_foundSystemPeripheralTimer 4
#define timeoutSec_connection 7


#import "BLEManage.h"
#import "BLEUtility.h"
#import "NSData+SY_AES.h"


static NSString * const kServiceUUID = @"0000fff0-0000-1000-8000-00805f9b34fb";

static NSString * const kCharacteristicUUID = @"fff6";//write


@interface BLEManage ()<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong,nonatomic)CBPeripheral *connectPeripheral;//正在连接的设备

@property (nonatomic,strong) NSString *serectString;

@property (nonatomic,assign) BOOL isAutoScan;



@end

@implementation BLEManage


-(instancetype)init
{
    self = [super init];
    if (self) {
        
        
        self.bleGCD = dispatch_queue_create("BLEgcd", NULL);
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:self.bleGCD];
        
        self.scanPeripheralArray = [[NSMutableArray alloc] init];
        
        
        Byte byte[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
        NSData *adata = [[NSData alloc] initWithBytes:byte length:16];
        self.serectString = [[NSString alloc] initWithData:adata encoding:NSUTF8StringEncoding];
        
    }
    return self;
}
static BLEManage * bleManager = nil;
+ (instancetype)shareBLEManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleManager = [[BLEManage alloc]init];
    });
    return bleManager;
}


#pragma  mark - 回调方法 检测中央设备状态
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        //如果蓝牙关闭，那么无法开启检测，直接返回
        
        NSLog(@"蓝牙关闭");
        return;
    }
}

-(void)startScanBLEDeviceWithAutoScan:(BOOL)autoScan{
    
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    NSLog(@"开始扫描");
    self.isAutoScan = autoScan;
}

-(void) stopScan{
    [self.centralManager stopScan];
}

/*
 peripheral：扫描到的周边设备
 advertisementData：响应数据  跟广播包所放的内容有关系
 RSSI即Received Signal Strength Indication：接收的信号强度指示
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    NSLog(@"扫描到的外设 :%@",peripheral);
    
    BOOL isFound = NO;
    
    if (peripheral.name == nil || [peripheral.name isEqualToString:@""]) {
        return;
    }
  
    if ([peripheral.name rangeOfString:@"LOCK"].location != NSNotFound) {
        
        for (NSDictionary *peripheralDict in self.scanPeripheralArray) {
            CBPeripheral *lastPeripheral = [peripheralDict objectForKey:@"Peripheral"];
            if ([lastPeripheral.identifier isEqual:peripheral.identifier]) {
                isFound   = YES;
            }
        }
        
        if (isFound == YES) {
            NSLog(@"添加过的");
        }else{
            
            NSData *macAdress = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
            NSString *deviceMac = [self getBleMAcAdressWithData:macAdress];
            NSDictionary *peripheralDict = @{@"Peripheral":peripheral,@"deviceMac":deviceMac};
            
            [self.scanPeripheralArray addObject:peripheralDict];
            
            if (self.isAutoScan == NO) {
                if ([self.delegate respondsToSelector:@selector(showScanPeripheralArray:)]) {
                    [self.delegate showScanPeripheralArray:self.scanPeripheralArray];
                }
            }
        }
    }
    
}



#pragma  mark - 回调方法 成功连接周边设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@" %s uuid  已连接 %@",__func__,peripheral.identifier.UUIDString);

    [self.centralManager stopScan];
    
    self.connectPeripheral.delegate = self;
    
    [self.connectPeripheral discoverServices:nil];
    

}


#pragma  mark -  蓝牙断开连接回调方法
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"centralManager 蓝牙断开连接");
    
    if ([self.delegate respondsToSelector:@selector(didDisconnectDevice:)]) {
        [self.delegate didDisconnectDevice:self.connectDevice];
    }
    
}

#pragma -mark 蓝牙连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%s error %@",__func__,error);
    
}


#pragma  mark - 回调方法 接收到连接的周边设备的服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        return;
    }
    
    //遍历周边设备的服务 通过代理返回特征
    for (CBService *service in peripheral.services) {
        //发现特征
        [peripheral discoverCharacteristics:nil forService:service];
        NSLog(@"service.UUID.UUIDString :%@",service.UUID.UUIDString);
    }
}



#pragma  mark - 回调方法 获取特征
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        return;
    }
    //判断是否是匹配的服务kServiceUUID
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kServiceUUID]]) {
        //遍历特征
        
        for (CBCharacteristic *characteristic in service.characteristics) {
            //找到我们需要的特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kCharacteristicUUID]]) {
                CBUUID *sUUID = [CBUUID UUIDWithString:kServiceUUID];
                CBUUID *cUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
                [BLEUtility setNotificationForCharacteristic:peripheral sCBUUID:sUUID cCBUUID:cUUID enable:YES];
                
            }
        }
    }
    
}



#pragma mark - 写完数据回调
-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"%s",__func__);
    if (error) {
        NSLog(@"报错 ：%@ ",peripheral);
        
        NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic,error);
        return;
    }
    
    NSLog(@"写数据完成");
}




#pragma  mark - 回调方法 —— 订阅状态改变
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if (error) {
        NSLog(@"%@",error);
        return;
    }
    NSLog(@"peripheral -%@ \n characteristic :%@",peripheral,characteristic);
    NSLog(@"使能通知完成,开始写入数据");
    
    [[NSUserDefaults standardUserDefaults] setObject:peripheral.identifier.UUIDString forKey:LastConnectDevice];
    
    [self writeDataToDeviceSendInstructions:ShakeHand];
    

    
}


#pragma  mark - 连接蓝牙
-(void)connectPeripheral:(DeviceModel *)deviceModel{
    
    for (NSDictionary *deviceDict in self.scanPeripheralArray) {
        CBPeripheral *peripheral = [deviceDict objectForKey:@"Peripheral"];
        
        if ([deviceModel.identifier isEqualToString:peripheral.identifier.UUIDString]) {
            [self.centralManager connectPeripheral:peripheral options:nil];
            self.connectDevice = deviceModel;
            self.connectPeripheral = peripheral;
        }
    }

}

-(void) writeDataToDeviceSendInstructions:(SendInstructions)sendInstructions {
    
    UInt8 SendData[20] = {0x0};
    NSInteger dataLength = 0;
    NSData *sendData = nil;

    NSLog(@"连接的device %@",self.connectDevice);
    NSString *key1 = [self.connectDevice.devicePassword substringWithRange:NSMakeRange(0, 2)];
    NSString *key2 = [self.connectDevice.devicePassword substringWithRange:NSMakeRange(2, 2)];
    NSString *key3 = [self.connectDevice.devicePassword substringWithRange:NSMakeRange(4, 2)];
    
    
    switch (sendInstructions) {
        case ShakeHand:
        {
 
            SendData[0] = 0x55;
            SendData[1] = 0x10;
            SendData[2] = 0x00;
            
            //D0~D5:蓝牙MAC
            NSString *pairCodeStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"pairCode"];
            NSInteger pairCode = 0;
            NSInteger pairSecond = 0;
            if (pairCodeStr ==nil || [pairCodeStr isEqualToString:@""]) {
                
                pairCode = arc4random() % (256 * 256 * 256);
                pairSecond = arc4random() % (256 * 256 * 256);
                pairCodeStr = [NSString stringWithFormat:@"%ld-%ld",(long)pairCode,(long)pairSecond];
                [[NSUserDefaults standardUserDefaults] setObject:pairCodeStr forKey:@"pairCode"];
                
            }else{
                
                NSArray *array2 = [pairCodeStr componentsSeparatedByString:@"-"];
                pairCode = [array2[0] integerValue];
                pairSecond = [array2[1] integerValue];
            }
            
            SendData[3] = (pairCode >> 16) & 0xff;
            SendData[4] = (pairCode >> 8) & 0xff;
            SendData[5] = pairCode  & 0xff;
            
            SendData[6] = (pairSecond >> 16) & 0xff;
            SendData[7] = (pairSecond >> 8) & 0xff;
            SendData[8] = pairSecond  & 0xff;
            
            dataLength = 9;
            sendData = [NSData dataWithBytes:SendData length:dataLength];
            NSLog(@"sendData :%@  - pairCodeStr:%@",sendData,pairCodeStr);

            
            break;
        }
        case LockState:
        {
            
            
            SendData[0] = 0x55;
            SendData[1] = 0x10;
            SendData[2] = 0x01;
            
            SendData[3] = 0x00;
            SendData[4] = 0x00;
            SendData[5] = 0x00;
            
            SendData[6] = 0x00;
            SendData[7] = 0x00;
            SendData[8] = 0x00;
            
            
            break;
        }
        case OpenLock:
        {
        
            
            SendData[0] = 0x55;
            SendData[1] = 0x10;
            SendData[2] = 0x02;
            
            SendData[3] = 0x01;
            SendData[4] = 0x00;
            SendData[5] = 0x00;
            
            SendData[6] = 0x00;
            SendData[7] = 0x00;
            SendData[8] = 0x00;
            
   
            break;
        }

  
        default:
            break;
    }
    

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
    CBUUID *sUUID = [CBUUID UUIDWithString:kServiceUUID];
    CBUUID *cUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    
    [self writeCharacteristic:self.connectPeripheral sCBUUID:sUUID cCBUUID:cUUID data:sendSerectData];
}
#pragma mark - 修改密码
-(void)changeCurrentDevicePassword:(DeviceModel *)currentDevice AndNewPassword:(NSString *)newPassword{
    
    UInt8 SendData[20] = {0x0};
    NSInteger dataLength = 0;
    NSData *sendData = nil;
    
    NSString *newKey1 = [newPassword substringWithRange:NSMakeRange(0, 2)];
    NSString *newKey2 = [newPassword substringWithRange:NSMakeRange(2, 2)];
    NSString *newKey3 = [newPassword substringWithRange:NSMakeRange(4, 2)];
    
    NSLog(@"连接的device %@",self.connectDevice);
    
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
    CBUUID *sUUID = [CBUUID UUIDWithString:kServiceUUID];
    CBUUID *cUUID = [CBUUID UUIDWithString:kCharacteristicUUID];
    
    [self writeCharacteristic:self.connectPeripheral sCBUUID:sUUID cCBUUID:cUUID data:sendSerectData];
}

#pragma  mark - 回调方法 接收到通知发来的数据
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",[error localizedDescription]);
        return;
    }
    
    [self dealWithBLEData:characteristic.value];
    
}

- (void)dealWithBLEData:(NSData *)bleData{
    
    
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
            
            if (dataVal[3] == 0xff) {
                NSLog(@"握手失败,没有权限");
                if ([self.delegate respondsToSelector:@selector(haveNoPermissionsToConnectDevice)]) {
                    [self.delegate haveNoPermissionsToConnectDevice];
                }
            }else{
                if (dataVal[3] == 0x00) {
                    NSLog(@"未上锁状态");
                    islock = NO;
                }else if(dataVal[3] == 0x01){
                    NSLog(@"上锁状态");
                    islock = YES;
                }
                if ([self.delegate respondsToSelector:@selector(connectDeviceSuccessfully)]) {
                    [self.delegate connectDeviceSuccessfully];
                    [self.delegate showTheLockState:islock];
                }
                
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


-(void)disconnectBLEDevice{
    NSLog(@"%s  断开蓝牙",__func__);
    
    if (self.connectPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.connectPeripheral];
    }
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}


-(UInt8)check_sum:(UInt8 *)data lenth:(UInt16)lenth
{
    UInt8 checksum = 0;
    UInt16 i = 0;
    for(i = 0;i < lenth;i ++)
    {
        checksum ^= data[i];
    }
    return checksum;
}

-(void)writeCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data {
    // Sends data to BLE peripheral to process HID and send EHIF command to PC
    for ( CBService *service in peripheral.services ) {
        //        NSLog(@"service--------------%@",service);
        if ([service.UUID isEqual:sCBUUID]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                //                NSLog(@"characteristic-------%@",characteristic);
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
                    
                }
            }
        }
    }
}

#pragma mark - 截取Mac地址
- (NSString *) getBleMAcAdressWithData:(NSData *)data{
    
    uint8_t dataVal[16] = {0x0};
    [data getBytes:&dataVal length:data.length];
    
    NSString *macAdress = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",dataVal[5],dataVal[4],dataVal[3],dataVal[2],dataVal[1],dataVal[0]];
    
    return macAdress;
}


@end
