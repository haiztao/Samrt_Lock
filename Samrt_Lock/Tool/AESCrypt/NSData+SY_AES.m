//
//  NSData+SY_AES.m
//  TestProject
//
//  Created by fuhuayou on 15/11/16.
//  Copyright (c) 2015年 fuhuayou. All rights reserved.
//

#import "NSData+SY_AES.h"

@implementation NSData (SY_AES)

+ (instancetype)shareInstance
{
    static NSData *myTools=nil;
    if (!myTools)
    {
        myTools = [[NSData alloc] init];
        
    }
    return myTools;
}

- (NSData *)AES128EncryptWithKey:(NSString *)key
{
    

    char keyPtr[kCCKeySizeAES128+1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSInteger dataLength = [self length];
    int diff = kCCKeySizeAES128 - (dataLength % kCCKeySizeAES128);
    NSInteger newSize = 0;
    
    if(diff > 0)
    {
        newSize = dataLength + diff;
    }
    
    char dataPtr[newSize];
    memcpy(dataPtr, [self bytes], [self length]);
    for(int i = 0; i < diff; i++)
    {
        dataPtr[i + dataLength] = 0x20;
    }
    
    size_t bufferSize = newSize + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,///kCCDecrypt
                                          kCCAlgorithmAES128,
                                          0x0000|kCCOptionECBMode,
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          NULL,
                                          dataPtr,
                                          sizeof(dataPtr),
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    
    if(cryptStatus == kCCSuccess)
    {
        return [NSData dataWithBytesNoCopy:buffer length:kCCKeySizeAES128] ;
    }
    
    return nil;
}

- (NSData *)AES128DecryptWithKey:(NSString *)key
{
    
   
    char keyPtr[kCCKeySizeAES128+1];
    //内存分配
    bzero(keyPtr, sizeof(keyPtr));
    //赋值，将key赋值给keyPtr
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSInteger dataLength = [self length];
    
    int diff = kCCKeySizeAES128 - (dataLength % kCCKeySizeAES128);
    NSInteger newSize = 0;
    
    if(diff > 0)
    {
        newSize = dataLength + diff;
    }
    
    char dataPtr[newSize];
    memcpy(dataPtr, [self bytes], [self length]);
    for(int i = 0; i < diff; i++)
    {
        dataPtr[i + dataLength] = 0x00;
    }
    
    size_t bufferSize = newSize + kCCBlockSizeAES128;
    //分配内存
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    //
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0x0000|kCCOptionECBMode,
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          NULL,
                                          dataPtr,
                                          sizeof(dataPtr),
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    
    if(cryptStatus == kCCSuccess)
    {
        return [NSData dataWithBytesNoCopy:buffer length:kCCKeySizeAES128];
    }
    
    return nil;
}


@end
