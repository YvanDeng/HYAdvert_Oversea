//
//  NSObject+HYJson.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (HYAdverCrypt)
@property (nonatomic, readonly) NSString *hy_md5String;
@property (nonatomic, readonly) NSString *hy_sha1String;
@property (nonatomic, readonly) NSString *hy_sha256String;
@property (nonatomic, readonly) NSString *hy_sha512String;
@end

@interface NSData (HYAdverAES128PKCS7)
- (NSData *)hy_AES128PKCS7EncryptWithKey:(NSString *)key iv:(NSString *)iv;
- (NSData *)hy_AES128PKCS7DecryptWithKey:(NSString *)key iv:(NSString *)iv;
@end

@interface NSObject (HYAdverJson)
- (NSString * _Nullable)hy_jsonString;
- (id _Nullable)hy_jsonValue;
@end

@interface NSDate (HYAdverDate)
+ (NSTimeInterval)hy_currentTime;
+ (BOOL)hy_isSameDayWithTimeInterval:(NSTimeInterval)timeInterval;
- (BOOL)hy_isSameDayWithDate:(NSDate *)refDate;
@end

@interface NSNumber (HYAdverRandom)
+ (NSNumber *)randomNumberFrom:(NSInteger)from to:(NSInteger)to;
+ (NSNumber *)randomNumber;
@end

NS_ASSUME_NONNULL_END
