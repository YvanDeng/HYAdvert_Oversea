//
//  HYAdvertConfig.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString * const signKey;
FOUNDATION_EXTERN NSString * const aesKey;
FOUNDATION_EXTERN NSString * const aesIv;

#define HYAdvertLog(FORMAT, ...) {\
if ([HYAdvertConfig logEnable]) { \
    NSLog((@"[HYAdvertLog:] %s [Line %d] \n" FORMAT), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
    }\
}\

@interface HYAdvertConfig : NSObject

/// environment
+ (void)setDebugEnv:(BOOL)debug;
+ (void)setDebugAddress:(NSString *)address;
+ (void)setReleaseAddress:(NSString *)address;
+ (NSString *)usingURLStr;

/// log
+ (void)setLogEnable:(BOOL)log;
+ (BOOL)logEnable;

// Info
+ (void)setU:(NSString *)u;
+ (void)setS:(NSString *)s;
+ (void)setQid:(NSString *)qid;
+ (void)setMcc:(NSString *)mcc;
+ (void)setUserKey:(NSString *)userKey;
+ (void)setVersion:(NSString *)version;
+ (void)setChannel:(NSString *)channel;
+ (void)setAppType:(NSInteger)appType;
+ (void)setSupportAdSource:(NSArray *)supportAdSource;

+ (NSString *)u;
+ (NSString *)s;
+ (NSString *)qid;
+ (NSString *)mcc;
+ (NSString *)userKey;
+ (NSString *)version;
+ (NSString *)channel;
+ (NSString *)appType;
+ (NSString *)platform;
+ (NSString *)sdkVersion;
+ (NSArray *)supportAdSource;

// Facebook审核 过滤广告
+ (void)setReadingMode:(NSInteger)readingMode;
+ (NSInteger)readingMode;

@end
