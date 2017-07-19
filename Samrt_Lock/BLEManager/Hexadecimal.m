//
//  Hexadecimal.m
//  WisDatInc
//
//  Created by Adsmart on 15/9/24.
//  Copyright © 2015年 adsmart. All rights reserved.
//

#import "Hexadecimal.h"

@implementation Hexadecimal

//16进制的字符串  转  十进制的字符串
+(NSString*)HexStringToDecimal:(NSString*)device_ID
{
    NSString * copyString = [device_ID copy];
    UInt64 uNumber = 0;
    
    char s1 = [copyString characterAtIndex:0];
    uNumber = uNumber + ([Hexadecimal bitStringToHex:s1] << 20);
    char s2 = [copyString characterAtIndex:1];
    uNumber = uNumber + ([Hexadecimal bitStringToHex:s2] << 16);
    char s3 = [copyString characterAtIndex:2];
    uNumber = uNumber + ([Hexadecimal bitStringToHex:s3] << 12);
    char s4 = [copyString characterAtIndex:3];
    uNumber = uNumber + ([Hexadecimal bitStringToHex:s4] << 8);
    char s5 = [copyString characterAtIndex:4];
    uNumber = uNumber + ([Hexadecimal bitStringToHex:s5] << 4);
    char s6 = [copyString characterAtIndex:5];
    uNumber = uNumber + ([Hexadecimal bitStringToHex:s6]);
    
    return [NSString stringWithFormat:@"%llu",uNumber];
    
}

+(NSInteger)bitStringToHex:(char)bit
{
    //    NSLog(@"%c",bit);
    switch (bit) {
        case '0':
            return 0;
            break;
        case '1':
            return 1;
            break;
        case '2':
            return 2;
            break;
        case '3':
            return 3;
            break;
        case '4':
            return 4;
            break;
        case '5':
            return 5;
            break;
        case '6':
            return 6;
            break;
        case '7':
            return 7;
            break;
        case '8':
            return 8;
            break;
        case '9':
            return 9;
            break;
        case 'a':
            return 10;
            break;
        case 'b':
            return 11;
            break;
        case 'c':
            return 12;
            break;
        case 'd':
            return 13;
            break;
        case 'e':
            return 14;
            break;
        case 'f':
            return 15;
            break;
            
        default:
            return 0;
            break;
    }
    
}


@end
