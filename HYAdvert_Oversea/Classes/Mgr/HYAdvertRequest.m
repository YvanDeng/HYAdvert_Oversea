//
//  HYAdvertRequest.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "HYAdvertRequest.h"
#import "HYAdvertParams.h"
#import "HYHttpMgr.h"
#import "NSObject+HYUtil.h"
#import "HYAdvert.h"
#import "HYAdvertCache.h"
#import "HYAdvertConfig.h"
#import "HYAdvertThirdSDK.h"
#import "HYAdvertControl.h"
#import "HYAdvertStatus.h"
#import "HYAdvertConstant.h"

#pragma mark - Encode && Decode

/// 解密
static id decodeData(id obj) {
    if (!obj) return nil;
    if ([obj isEqual:[NSNull null]]) return nil;
    
    NSData *data = [obj dataUsingEncoding:NSUTF8StringEncoding];
    id value = [[data hy_AES128PKCS7DecryptWithKey:aesKey iv:aesIv] hy_jsonValue];
    HYAdvertLog(@"decodeData = %@", value);
    return value;
}

/// 编码URL, 防止有中文等特殊字符
static NSURL *encodeURL(NSString *URLStr) {
    if (!URLStr) return nil;
    NSString *str = [URLStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSURL URLWithString:str];
}

@implementation HYAdvertRequest

#pragma mark - Normal

/// 重试次数
NSUInteger retryCount = 3;
/// 缓存广告数据
static void cacheAdvertResults(NSDictionary *results) {
    [HYAdvertCache cacheAdverts:results];
}

/// 获取历史广告数据
static NSDictionary * historyAdvertResults() {
    NSDictionary *adverts = [HYAdvertCache historyAdverts];
    if (!adverts) adverts = @{};
    return adverts;
}

/// 获取历史广告数据状态
static NSDictionary * historyAdvertStatus() {
    NSDictionary *status = [HYAdvertCache historyAdvertStatus];
    if (!status) status = @{};
    return status;
}

/// 缓存广告数据状态
static void cacheAdvertStatus(NSDictionary *status) {
    [HYAdvertCache cacheAdvertStatus:status];
}

/// 下载
static NSMutableArray * _Nonnull imageURLs;
static NSMutableArray * _Nonnull videoURLStrs;
static void downLoadResources() {
    [HYAdvertCache downLoadImageWithURLs:imageURLs.copy];
    [HYAdvertCache downVideosWithURLStrs:videoURLStrs.copy];
}

/// Mapping
static NSArray *advertItems(NSArray *array, NSDictionary *advertStatus, NSString *pid) {
    NSMutableArray *results = [NSMutableArray array];
    NSTimeInterval curTime = [NSDate hy_currentTime];
    
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) continue;
        
        NSTimeInterval endTime = [dict[@"endTime"] doubleValue];
        if (curTime > endTime) continue;   // 剔除过期的数据
        
        HYAdvert *advert = [HYAdvert advertWithDict:dict pid:pid source:HYAdvertSourceNormal];
        if (!advert) continue;
        [results addObject:advert];
        
        NSDictionary *sourceTypeDict = advertStatus[advert.adSource];
        HYAdvertStatus *status = sourceTypeDict[advert.pid];
        if (status) { /// 同步新的配置
            status.showCount = advert.hasShowedCount;
        }
        
        /// 存储资源
        if (advert.showMode == HYAdvertDataVideo) {
            if (!advert.adUrl || advert.adUrl.length == 0) continue;
            [videoURLStrs addObject:advert.adUrl];
        } else if (advert.showMode == HYAdvertDataPic
                   || advert.showMode == HYAdvertDataGif) {
            if (!advert.adUrl || advert.adUrl.length == 0) continue;
            NSURL *url = encodeURL(advert.adUrl);
            if (url) [imageURLs addObject:url];
        } else if (advert.showMode == HYAdvertDataPicLoop) {
            for (HYAdvertContent *adc in advert.adList) {
                if (!adc.adUrl || advert.adUrl.length == 0) continue;
                NSURL *url = encodeURL(adc.adUrl);
                if (url) [imageURLs addObject:url];
            }
        }
    }
    return [results copy];
}

/// 获取广告配置，dreame 暂未使用
+ (void)getAdvertsWithLocal:(void (^)(NSDictionary *results, NSDictionary *advertStatus))local
                    netWork:(void (^)(NSDictionary *results, NSDictionary *advertStatus))netWork
                    failure:(void (^)(NSString *error))failure {
    // 初始化需要下载的图片数组
    imageURLs = @[].mutableCopy;
    videoURLStrs = @[].mutableCopy;
    
    /// 1.先读取缓存
    __block NSDictionary *status = nil;
    if (local) {
        status = historyAdvertStatus(); // 获取历史状态
        NSDictionary *locals = historyAdvertResults(); // 获取历史广告
        local(locals, status);
    }
    
    /// 2.请求新数据, 并更新
    NSDictionary *params = [HYAdvertParams baseParams];
    [[HYHttpMgr manager] postWithURL:@"/get" params:params success:^(id response) {
        if (netWork) {
            id obj = response[@"data"];
            NSArray *value = decodeData(obj);
            
            if (![value isKindOfClass:[NSArray class]]) {
                 if (failure) failure(nil);
                 return;
            }
            
            /// parser
            NSMutableDictionary *results = [NSMutableDictionary dictionary];
            for (NSDictionary *dict in value) {
                if (![dict isKindOfClass:[NSDictionary class]]) continue;
                NSString *pid = [NSString stringWithFormat:@"%@", dict[@"pid"]];
                NSMutableDictionary *pidDict = [NSMutableDictionary dictionary];
                
                /// sdk
                NSDictionary *sdk = dict[@"sdk"];
                HYAdvertThirdSDK *sdkConfig = [HYAdvertThirdSDK thirdSDKWithDict:sdk pid:pid];
                pidDict[@"sdk"] = sdkConfig;
                
                /// config
                NSDictionary *config = dict[@"config"];
                HYAdvertControl *advertConfig = [HYAdvertControl advertControlWithDict:config pid:pid];
                pidDict[@"config"] = advertConfig;
                
                /// item
                NSArray *items = dict[@"item"];
                if (![items isKindOfClass:[NSArray class]]) continue;
                NSDictionary *advertStatus = status[pid];
                NSArray *result = advertItems(items, advertStatus, pid);
                pidDict[@"item"] = result;
                
                results[pid] = [pidDict copy];
            }
            
            downLoadResources();/// 下载
            NSDictionary *netWorks = [results copy];
            cacheAdvertResults(netWorks); // 存储
            cacheAdvertStatus(status); // 存储新的状态
            netWork(netWorks, status);
            retryCount = 3;
        }
    } failure:^(NSError *error) {
        if (retryCount > 0) { // 重试3次
            retryCount--;
            [self getAdvertsWithLocal:local netWork:netWork failure:failure];
        } else {
            if (failure) {
                failure(error.description);
            }
        }
    }];
}

#pragma mark - RealTime

/// 缓存实时广告数据
static void cacheRealTimeAdverts(NSDictionary *adverts) {
    [HYAdvertCache cacheRealTimeAdverts:adverts];
}

/// 获取历史实时广告数据状态
static NSDictionary *historyRealTimeAdvertStatus() {
    NSDictionary *status = [HYAdvertCache historyRealTimeAdvertStatus];
    if (!status) status = @{};
    return status;
}

/// 缓存实时广告数据状态
static void cacheRealTimeAdvertStatus(NSDictionary *status) {
    [HYAdvertCache cacheRealTimeAdvertStatus:status];
}

/// Mapping
static NSArray<HYAdvert *> *parseRealTimeAdverts(NSArray *array, NSDictionary *sourceStatusDict, NSString *pid, NSMutableArray *realTimeImageURLs, NSMutableArray *realTimeVideoURLStrs) {
    NSMutableArray<HYAdvert *> *results = [NSMutableArray array];
    NSTimeInterval curTime = [NSDate hy_currentTime];
    
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) continue;
        
        NSTimeInterval endTime = [dict[@"endTime"] doubleValue];
        if (curTime > endTime) continue; // 剔除过期的数据
        
        /// 解析广告模型
        HYAdvert *advert = [HYAdvert advertWithDict:dict pid:pid source:HYAdvertSourceRealTime];
        if (!advert) continue;
        [results addObject:advert];
        
        /// 广告状态同步
        NSDictionary *advertStatusDict = sourceStatusDict[advert.adSource];
        HYAdvertStatus *advertStatus = advertStatusDict[advert.pid];
        if (advertStatus) { /// 同步新的配置
            advertStatus.showCount = advert.hasShowedCount;
//            advertStatus.showCountDaily = 0; // 实时的需要清空
        }
        
        /// 存储资源
        for (HYAdvertContent *adc in advert.adList) {
            if (!adc.adUrl || adc.adUrl.length == 0) continue;
            
            switch (advert.showMode) {
                case HYAdvertDataVideo:
                    [realTimeVideoURLStrs addObject:adc.adUrl];
                    break;
                case HYAdvertDataTextLoop:
                    break;
                default: {
                    NSURL *url = encodeURL(adc.adUrl);
                    if (url) [realTimeImageURLs addObject:url];
                }
                    break;
            }
        }
    }
    return [results copy];
}

/// 实时获取单条数据
+ (void)getByRealTimeAdvertWithPid:(NSString *)pid completion:(void (^)(NSDictionary *, NSDictionary *, NSDictionary *, NSError *))completion {
    NSDictionary *params = [HYAdvertParams realTimeParamsWithPid:pid];
    [[HYHttpMgr manager] postWithURL:@"/getByRealTime" params:params success:^(id response) {
        id obj = response[@"data"];
        // 先进行 AES128 解密，再对 json 进行解析
        id value = decodeData(obj);
        if (![value isKindOfClass:[NSArray class]]) {
            if (completion) {
                if (value) {
                    // 后台返回格式有误，比如返回了字典
                    NSError *error = [NSError errorWithDomain:@"HYAdvertErrorDomain" code:HYAdvertErrorResponseFormatInvalid userInfo:@{NSLocalizedDescriptionKey : @"Decode response is not json array!"}];
                    completion(nil, nil, nil, error);
                } else {
                    // 该广告位还未配置广告
                    completion(nil, nil, nil, nil);
                }
            }
            return;
        }
        
        /// Mapping
        // 旧的实时广告数据
        NSMutableDictionary *realTimeAdvertsDict = [HYAdvertCache historyRealTimeAdverts].mutableCopy;
        // 旧的实时广告状态
        NSMutableDictionary *realTimeAdvertStatusDict = historyRealTimeAdvertStatus().mutableCopy;
        
        /// 待下载资源 url 数组
        NSMutableArray *realTimeImageURLs = @[].mutableCopy;
        NSMutableArray *realTimeVideoURLStrs = @[].mutableCopy;
        
        /// 记录回调的原始数据
        NSDictionary *results;
        
        // 遍历
        for (NSDictionary *dict in value) {
            if (![dict isKindOfClass:[NSDictionary class]]) continue;
            results = dict;
            
            if ([dict[@"isDelLocal"] integerValue] == 2) { // 删除本地该广告位的广告
                // 过滤
                realTimeAdvertsDict[pid] = nil;
                realTimeAdvertStatusDict[pid] = nil;
                // 存储
                cacheRealTimeAdverts(realTimeAdvertsDict.copy);
                cacheRealTimeAdvertStatus(realTimeAdvertStatusDict.copy);
            } else if ([dict[@"isDelLocal"] integerValue] == 0) {  // 正常数据
                // 解析
                NSDictionary *sourceStatusDict = realTimeAdvertStatusDict[pid];
                NSArray<HYAdvert *> *result = parseRealTimeAdverts(@[dict], sourceStatusDict, pid, realTimeImageURLs, realTimeVideoURLStrs);
                realTimeAdvertsDict[pid] = result;
                // 存储
                cacheRealTimeAdverts(realTimeAdvertsDict.copy);
                cacheRealTimeAdvertStatus(realTimeAdvertStatusDict.copy);
            } else if([dict[@"isDelLocal"] integerValue] == 1) {  // 无数据
                // 不做处理，展示缓存广告
            }
        }
    
        NSDictionary *advertDict = realTimeAdvertsDict.copy;
        NSDictionary *advertStatusDict = realTimeAdvertStatusDict.copy;
        
        if (realTimeImageURLs.count > 0 || realTimeVideoURLStrs.count > 0) {
            // 实时下载资源后再回调，这里未处理下载失败的情况(还有区分部分失败的场景)
            [HYAdvertCache downLoadingWithImageURLs:realTimeImageURLs.copy videosURLStrs:realTimeVideoURLStrs.copy completion:^(NSError * _Nullable error) {
                if (completion) completion(advertDict, advertStatusDict, results, error);
            }];
        } else {
            // 正常回调数据
            if (completion) completion(advertDict, advertStatusDict, results, nil);
        }
    } failure:^(NSError * _Nonnull error) {
        if (completion) {
            completion(nil, nil, nil, error);
        }
    }];
}

@end
