//
//  NSData+SY_AES.h
//  TestProject
//
//  Created by fuhuayou on 15/11/16.
//  Copyright (c) 2015年 fuhuayou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
@interface NSData (SY_AES)
//================================
//AES ECB 128 加密
//================================
+ (instancetype)shareInstance;
- (NSData *)AES128EncryptWithKey:(NSString *)key;
- (NSData *)AES128DecryptWithKey:(NSString *)key;
@end
