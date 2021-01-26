//
//  NSObject+HYJson.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "NSObject+HYUtil.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "HYBase64.h"

@implementation NSData (HYAdverAES128PKCS7)
- (NSData *)hy_AES128PKCS7EncryptWithKey:(NSString *)key iv:(NSString *)iv {
    char keyPtr[kCCKeySizeAES128+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCKeySizeAES128+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [self bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
        
        return [[HYBase64 stringByEncodingData:resultData] dataUsingEncoding:NSUTF8StringEncoding];
    }
    free(buffer);
    return nil;
}


- (NSData *)hy_AES128PKCS7DecryptWithKey:(NSString *)key iv:(NSString *)iv {
    char keyPtr[kCCKeySizeAES128+1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCKeySizeAES128+1];
    memset(ivPtr, 0, sizeof(ivPtr));
    [iv getCString:ivPtr maxLength:sizeof(ivPtr) encoding:NSUTF8StringEncoding];
    
    NSData *data = [HYBase64 decodeData:[[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

@end

@implementation NSString (HYAdverCrypt)

- (NSString *)hy_md5String {
    const char *str = self.UTF8String;
    int length = (int)strlen(str);
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, length, bytes);
    
    return [self stringFromBytes:bytes length:CC_MD5_DIGEST_LENGTH];
}

- (NSString *)hy_sha1String {
    const char *str = self.UTF8String;
    int length = (int)strlen(str);
    unsigned char bytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(str, length, bytes);
    
    return [self stringFromBytes:bytes length:CC_SHA1_DIGEST_LENGTH];
}

- (NSString *)hy_sha256String {
    const char *str = self.UTF8String;
    int length = (int)strlen(str);
    unsigned char bytes[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, length, bytes);
    
    return [self stringFromBytes:bytes length:CC_SHA256_DIGEST_LENGTH];
}

- (NSString *)hy_sha512String {
    const char *str = self.UTF8String;
    int length = (int)strlen(str);
    unsigned char bytes[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(str, length, bytes);
    
    return [self stringFromBytes:bytes length:CC_SHA512_DIGEST_LENGTH];
}

- (NSString *)stringFromBytes:(unsigned char *)bytes length:(int)length {
    NSMutableString *strM = [NSMutableString string];
    
    for (int i = 0; i < length; i++) {
        [strM appendFormat:@"%02x", bytes[i]];
    }
    
    return [strM copy];
}
@end

@implementation NSObject (HYAdverJson)
- (id)hy_jsonValue {
    NSError *error = nil;
    id obj = nil;
    NSData *data = (NSData *)self;
    if ([self isKindOfClass:[NSString class]]) {
        data = [(NSString *)self dataUsingEncoding:NSUTF8StringEncoding];
    }
    @try {
        obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments
                                                error:&error];
    } @catch (NSException *exception) {}
    return obj;
}

- (NSString *)hy_jsonString {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonStr = nil;
    if (!jsonData) return jsonStr;
    
    jsonStr = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSRange range = {0,jsonStr.length};
    
    NSMutableString *newStr = [NSMutableString stringWithString:jsonStr];
    [newStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    
    NSRange newRange = {0,newStr.length};
    [newStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:newRange];
    return newStr;
    
    return jsonStr;
}@end

@implementation NSDate (HYAdverDate)
+ (NSTimeInterval)hy_currentTime {
    return [[NSDate date] timeIntervalSince1970];
}

+ (BOOL)hy_isSameDayWithTimeInterval:(NSTimeInterval)timeInterval {
    NSTimeInterval curTime = [NSDate hy_currentTime];
    NSDate *curDate = [NSDate dateWithTimeIntervalSinceNow:curTime];
    NSDate *lastDate = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
    return [curDate hy_isSameDayWithDate:lastDate];
}

- (BOOL)hy_isSameDayWithDate:(NSDate *)refDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy.MM.dd";
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
    NSString *refDateString = [dateFormatter stringFromDate:refDate];
    NSString *currentDateString = [dateFormatter stringFromDate:self];
    return [refDateString isEqualToString:currentDateString];
}
@end

@implementation NSNumber (HYAdverRandom)
+ (NSNumber *)randomNumberFrom:(NSInteger)from to:(NSInteger)to {
    return @((int)(from + (arc4random() % (to - from + 1))));
}

+ (NSNumber *)randomNumber {
    return @(arc4random());
}
@end
