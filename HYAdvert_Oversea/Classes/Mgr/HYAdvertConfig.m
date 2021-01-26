//
//  HYAdvertConfig.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "HYAdvertConfig.h"

NSString * const signKey = @"123e49bf008a29609857515a10cf9222";
NSString * const aesKey = @"62533c4bde722e2a";
NSString * const aesIv = @"f840b1bf6af98bec";

static const NSString * _debugURLStr = @"http://172.31.0.118:10003";
static const NSString * _releaseURLStr = @"http://api.ad.yipinread.com";
static const NSString * _usingURLStr;

static BOOL _logEnable = NO;

@implementation HYAdvertConfig

+ (void)setLogEnable:(BOOL)log {
    _logEnable = log;
}

+ (BOOL)logEnable {
    return _logEnable;
}

+ (void)setDebugAddress:(NSString *)address {
    _debugURLStr = address;
}

+ (void)setReleaseAddress:(NSString *)address {
    _releaseURLStr = address;
}

+ (void)setDebugEnv:(BOOL)debug {
    if (debug) {
        _usingURLStr = _debugURLStr;
    } else {
        _usingURLStr = _releaseURLStr;
    }
}

+ (const NSString *)usingURLStr {
    return _usingURLStr;
}

#pragma mark - Infos

static const NSString *_u;
static const NSString *_s;
static const NSString *_qid;
static const NSString *_mcc;
static const NSString *_userKey;
static const NSString *_version;
static const NSString *_channel;
static const NSString *_appType;
static const NSString *_platform = @"2";
static const NSString *_sdkVersion = @"1.5.10";
static const NSArray *_supportAdSource = nil;
static NSInteger _readingMode = 1;

/// Setter
+ (void)setU:(NSString *)u {_u = u;}
+ (void)setS:(NSString *)s {_s = s;}
+ (void)setQid:(NSString *)qid {_qid = qid;}
+ (void)setMcc:(NSString *)mcc {_mcc = mcc;}
+ (void)setUserKey:(NSString *)userKey {_userKey = userKey;}
+ (void)setVersion:(NSString *)version {_version = version;}
+ (void)setChannel:(NSString *)channel {_channel = channel;}
+ (void)setAppType:(NSInteger)appType {_appType = [NSString stringWithFormat:@"%zd", appType];}
+ (void)setSupportAdSource:(NSArray *)supportAdSource {_supportAdSource =  supportAdSource;}
+ (void)setReadingMode:(NSInteger)readingMode {_readingMode = readingMode;}

/// Getter
+ (const NSString *)u {return _u;}
+ (const NSString *)s {return _s;}
+ (const NSString *)qid {return _qid;}
+ (const NSString *)mcc {return _mcc;}
+ (const NSString *)userKey {return _userKey;}
+ (const NSString *)version {return _version;}
+ (const NSString *)channel {return _channel;}
+ (const NSString *)appType {return _appType;}
+ (const NSString *)platform {return _platform;}
+ (const NSString *)sdkVersion {return _sdkVersion;}
+ (const NSArray *)supportAdSource {return _supportAdSource;}
+ (NSInteger)readingMode {return _readingMode;}

@end
