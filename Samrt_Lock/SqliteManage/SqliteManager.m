//
//  SqliteManager.m
//  Samrt_Lock
//
//  Created by haitao on 16/7/2.
//  Copyright © 2016年 haitao. All rights reserved.
//

#import "SqliteManager.h"
#import <FMDB.h>



static FMDatabaseQueue *fmdbQueue = nil;

@interface SqliteManager ()

@property (copy,nonatomic)NSString *dbFilePath;
/** FMDatabase *DB*/
@property (nonatomic , strong) FMDatabase *dataBase;

@end

@implementation SqliteManager

static SqliteManager *sqliteManager = nil;
+(instancetype)shareSqliteManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sqliteManager = [[SqliteManager alloc] init];
    });
    return sqliteManager;
}

-(id)init{
    
    self = [super init];
    //在document路径下创建数据库路径//通过搜素方式找到沙盒下 Document文件夹路径
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    //创建数据库对象
    NSString *SQLPath = [docPath stringByAppendingPathComponent:@"FMDB.sqlite"];
    NSLog(@"SQLPath = %@",SQLPath);
    
    _dataBase =[FMDatabase databaseWithPath:SQLPath];
    
    self.dbFilePath = SQLPath;
    if ([_dataBase open]) {
        
        [self createSqliteTable];
        
        fmdbQueue = [[FMDatabaseQueue alloc]initWithPath:_dbFilePath];
    }
    
    return self;
}



#pragma mark - 创建表格
-(void)createSqliteTable {
    [self.dataBase open];
    [self.dataBase executeUpdate:@"CREATE TABLE IF  NOT EXISTS BLE_Device_Table (rowid INTEGER PRIMARY KEY AUTOINCREMENT, deviceMac text, deviceName text, devicePassword text, identifier text)"];
    [self.dataBase executeUpdate:@"CREATE TABLE IF  NOT EXISTS WIFI_Device_Table (rowid INTEGER PRIMARY KEY AUTOINCREMENT, deviceMac text, deviceName text, devicePassword text)"];
    [self.dataBase close];
}


//---------------------------------华丽的分割线----------------------------------------------------
#pragma mark - BLE数据 --  增删改查
//插入一条数据
- (void)insterDeviceInfo:(DeviceModel *)device{
    
    NSLog(@"insert");
    [self.dataBase open];
    [self.dataBase executeUpdate:@"INSERT INTO BLE_Device_Table (deviceMac,deviceName,devicePassword,identifier) VALUES (?,?,?,?)",device.deviceMac,device.deviceName,device.devicePassword,device.identifier];
    [self.dataBase close];
    
}

/**
 *  删除数据库里面 一类deviceMac数据
 *
 *  @param student 模型
 */
- (void)deleteDeviceInfo:(DeviceModel *)device{
    [self.dataBase open];
    [self.dataBase executeUpdate:@"DELETE FROM BLE_Device_Table WHERE deviceMac = ?",device.deviceMac];
    [self.dataBase close];
}

/**
 *  更新一个deviceMac的数据
 *
 *  @param WifiDeviceModel数据模型
 */
- (void)updateDeviceInfo:(DeviceModel *)device{
    [self.dataBase open];
    
//    NSLog(@"update device %@",device);
    
    BOOL result = [self.dataBase executeUpdate:@"UPDATE BLE_Device_Table SET deviceName=?,devicePassword=?,identifier=? WHERE deviceMac=?",device.deviceName, device.devicePassword,device.identifier,device.deviceMac];
    
    [self.dataBase close]; 
    
    if (result == NO) {
        NSLog(@"%s  error %@",__func__,self.dataBase.lastErrorMessage);
    }
}

/**
 *  获取表中的所有数据 以WifiDeviceModel的形式存储在数组中
 *
 *  @return 表中的数据
 */
- (NSMutableArray *)getAllDeviceInfo{
    [self.dataBase open];
    FMResultSet *result = [self.dataBase executeQuery:@"SELECT * FROM BLE_Device_Table"];
    
    NSMutableArray *allDeviceArray = [[NSMutableArray alloc]init];
    
    while ([result next]) {
        
        DeviceModel *model = [DeviceModel creatBLEDeviceMac:[result stringForColumn:@"deviceMac"] deviceName:[result stringForColumn:@"deviceName"] devicePass:[result stringForColumn:@"devicePassword"] identifier:[result stringForColumn:@"identifier"]];
        
        [allDeviceArray addObject:model];
        
    }
    [self.dataBase close];
    
    return allDeviceArray;
    
}


/**
 *  根据deviceMac 查找设备
 *
 *  @param deviceMac
 *
 *  @return 设备数组
 */
- (NSMutableArray *)getDeviceMac:(NSString *)deviceMac{
    [self.dataBase open];
    FMResultSet *result = [self.dataBase executeQuery:@"SELECT * FROM BLE_Device_Table WHERE deviceMac = ?",deviceMac];
    NSMutableArray *stuArray = [[NSMutableArray alloc] init];
    while ([result next]) {
        DeviceModel *model = [DeviceModel creatBLEDeviceMac:[result stringForColumn:@"deviceMac"] deviceName:[result stringForColumn:@"deviceName"] devicePass:[result stringForColumn:@"devicePassword"] identifier:[result stringForColumn:@"identifier"]];
        [stuArray addObject:model];
    }
    [self.dataBase close];
    return stuArray;
}

//-----------------------------------------------------------------------------------------------------

#pragma mark - WiFi数据 ------ 增删改查

//插入一条数据
- (void)insterWifiDeviceInfo:(DeviceModel *)device{
    
    NSLog(@"insert");
    [self.dataBase open];
    [self.dataBase executeUpdate:@"INSERT INTO WIFI_Device_Table (deviceMac,deviceName,devicePassword) VALUES (?,?,?)",device.deviceMac,device.deviceName,device.devicePassword];
    [self.dataBase close];
    
}

/**
 *  删除数据库里面 一类deviceMac数据
 *
 *  @param student 模型
 */
- (void)deleteWifiDeviceInfo:(DeviceModel *)device{
    [self.dataBase open];
    [self.dataBase executeUpdate:@"DELETE FROM WIFI_Device_Table WHERE deviceMac = ?",device.deviceMac];
    [self.dataBase close];
}

/**
 *  更新一个deviceMac的数据
 *
 *  @param WifiDeviceModel数据模型
 */
- (void)updateWifiDeviceInfo:(DeviceModel *)device{
    [self.dataBase open];
    
    NSLog(@"update wifi device %@",device);
    
    BOOL result = [self.dataBase executeUpdate:@"UPDATE WIFI_Device_Table SET deviceName=?,devicePassword=? WHERE deviceMac=?",device.deviceName, device.devicePassword,device.deviceMac];
    
    [self.dataBase close];
    
    if (result == NO) {
        NSLog(@" %s  error %@",__func__,self.dataBase.lastErrorMessage);
    }
}

/**
 *  获取表中的所有数据 以WifiDeviceModel的形式存储在数组中
 *
 *  @return 表中的数据
 */
- (NSMutableArray *)getAllWifiDeviceInfo{
    [self.dataBase open];
    FMResultSet *result = [self.dataBase executeQuery:@"SELECT * FROM WIFI_Device_Table"];
    
    NSMutableArray *allDeviceArray = [[NSMutableArray alloc]init];
    
    while ([result next]) {
        
        DeviceModel *model = [DeviceModel creatWIFIDeviceMac:[result stringForColumn:@"deviceMac"] deviceName:[result stringForColumn:@"deviceName"] devicePass:[result stringForColumn:@"devicePassword"]];
        
        [allDeviceArray addObject:model];
        
    }
    [self.dataBase close];
    
    return allDeviceArray;
    
}


/**
 *  根据deviceMac 查找设备
 *
 *  @param deviceMac
 *
 *  @return 设备数组
 */
- (NSMutableArray *)getWifiDeviceMac:(NSString *)deviceMac{
    [self.dataBase open];
    FMResultSet *result = [self.dataBase executeQuery:@"SELECT * FROM WIFI_Device_Table WHERE deviceMac = ?",deviceMac];
    NSMutableArray *stuArray = [[NSMutableArray alloc] init];
    while ([result next]) {
        DeviceModel *model = [DeviceModel creatWIFIDeviceMac:[result stringForColumn:@"deviceMac"] deviceName:[result stringForColumn:@"deviceName"] devicePass:[result stringForColumn:@"devicePassword"]];
        [stuArray addObject:model];
    }
    [self.dataBase close];
    return stuArray;
}






@end
