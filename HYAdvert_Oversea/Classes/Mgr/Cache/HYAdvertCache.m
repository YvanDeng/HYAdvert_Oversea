//
//  HYAdvertCache.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/14.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "HYAdvertCache.h"
#import "HYDownloadMgr.h"
#import "HYAdvertConstant.h"

#import <SDWebImage/SDWebImage.h>
#import <objc/message.h>

static NSString * const HYAdvertHasClearCacheKey = @"com.dreame.HYAdvert_Oversea.HYAdvertHasClearCache";

static inline NSString *adPath() {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:@"HYAdvert"];
}

static inline NSString *adStatusPath() {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:@"HYAdvertStatus"];
}

static inline NSString *adRealTimePath() {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:@"HYRealTimeAdvert"];
}

static inline NSString *adRealTimeStatusPath() {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:@"HYRealTimeAdvertStatus"];
}

static inline NSString *reportsPath() {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
            stringByAppendingPathComponent:@"HYAdvertReports"];
}

@implementation HYAdvertCache

// SDK升级，清理缓存
+ (void)clearAllCachesWithSDKVersion:(NSString *)sdkVersion {
    NSString *key = [NSString stringWithFormat:@"%@_%@", HYAdvertHasClearCacheKey, sdkVersion];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:key]) return;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:adPath()]) {
        [fileManager removeItemAtPath:adPath() error:nil];
    }
    if ([fileManager fileExistsAtPath:adStatusPath()]) {
        [fileManager removeItemAtPath:adStatusPath() error:nil];
    }
    if ([fileManager fileExistsAtPath:adRealTimePath()]) {
        [fileManager removeItemAtPath:adRealTimePath() error:nil];
    }
    if ([fileManager fileExistsAtPath:adRealTimeStatusPath()]) {
        [fileManager removeItemAtPath:adRealTimeStatusPath() error:nil];
    }
    if ([fileManager fileExistsAtPath:reportsPath()]) {
        [fileManager removeItemAtPath:reportsPath() error:nil];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 检测图片是否已经缓存
 
 @param urlStr 图片链接
 @return YES/NO
 */
+ (BOOL)existImageWithURLStr:(NSString *)urlStr {
    if (!urlStr || ![urlStr isKindOfClass:[NSString class]]) return NO;
    return [self diskImageExistsWithKey:urlStr];
}

+ (BOOL)diskImageExistsWithKey:(NSString *)key {
    return [SDImageCache.sharedImageCache diskImageDataExistsWithKey:key];
}

+ (NSString *)videoPathWithURLStr:(NSString *)urlStr {
    if (![urlStr isKindOfClass:[NSString class]]) return nil;
    return [HYDownloadMgr.manager fileExsitsWithKey:urlStr];
}

/**
 下载图片
 @param urls 图片链接
 */
+ (void)downLoadImageWithURLs:(NSArray<NSURL *> *)urls {
    if (!urls) return;
    [SDWebImagePrefetcher.sharedImagePrefetcher prefetchURLs:urls];
}

/// 添加后台下载 MD5的校验
+ (void)downVideosWithURLStrs:(NSArray<NSString *> *)URLStrs {
    [HYDownloadMgr.manager downloadWithURLStrs:URLStrs];
    [HYDownloadMgr.manager cacheVideosMetaDataWithURLStrs:URLStrs];
}

+ (void)downLoadingWithImageURLs:(NSArray<NSURL *> *)imageURLs videosURLStrs:(NSArray<NSString *> *)videosURLStrs completion:(void (^)(NSError * _Nullable))completion {
    // 下载组，一个广告位中的所有资源下载完成后，才回调
    dispatch_group_t group = dispatch_group_create();
    
    __block NSInteger successCount = 0;
    
    if (imageURLs) {
        void (*hy_download)(id, SEL, id, NSInteger, id, id) = (void(*)(id, SEL, id, NSInteger, id, id))objc_msgSend;
        
        for (NSURL *url in imageURLs) {
            
            dispatch_group_enter(group);
            
            if ([[SDWebImageManager sharedManager] respondsToSelector:@selector(loadImageWithURL:options:progress:completed:)]) {
                
                SDInternalCompletionBlock block = ^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                    if (!error) successCount += 1;
                    dispatch_group_leave(group);
                };
                
                hy_download([SDWebImageManager sharedManager], @selector(loadImageWithURL:options:progress:completed:), url, SDWebImageHighPriority, nil, block);
            }
        }
    }
    
    // 暂不处理视频的下载成功与否
    if (videosURLStrs) { // 视频
        for (NSString *URLStr in videosURLStrs) {
            if (!URLStr) continue;
            
            dispatch_group_enter(group);
            [[HYDownloadMgr manager] downloadWithURLStr:URLStr completion:^{
                dispatch_group_leave(group);
            }];
        }
        
        [[HYDownloadMgr manager] cacheVideosMetaDataWithURLStrs:videosURLStrs];
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
        if (completion) {
            if (successCount == imageURLs.count) {
                completion(nil);
            } else {
                NSError *error = [NSError errorWithDomain:@"HYAdvertErrorDomain" code:HYAdvertErrorResourceDownloadFailed userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"HYAdvert %@ Resource Download failed!", successCount == 0 ? @"All" : @"A part of"]}];
                completion(error);
            }
        }
    });
}

#pragma mark - Normal AD

/**
 存储广告数据
 */
+ (void)cacheAdverts:(NSDictionary *)adverts {
    NSDictionary *data = adverts;
    if (!adverts) data = @{};
    [NSKeyedArchiver archiveRootObject:data toFile:adPath()];
}

/**
 获取历史广告数据
 */
+ (NSDictionary *)historyAdverts {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:adPath()];
}

/**
 存储已显示广告的状态
 */
+ (void)cacheAdvertStatus:(NSDictionary<NSString *, NSDictionary<NSString *,NSDictionary<NSString *,HYAdvertStatus *> *> *> *)advertStatus {
    NSDictionary *data = advertStatus;
    if (!advertStatus) data = @{};
    [NSKeyedArchiver archiveRootObject:data toFile:adStatusPath()];
}

/**
 返回已显示广告的状态
 */
+ (NSDictionary<NSString *, NSDictionary<NSString *,NSDictionary<NSString *,HYAdvertStatus *> *> *> *)historyAdvertStatus {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:adStatusPath()];
}

#pragma mark - RealTime AD

/**
 存储实时广告数据
 */
+ (void)cacheRealTimeAdverts:(NSDictionary<NSString *, NSArray<HYAdvert *> *> * _Nonnull)adverts {
    NSDictionary *data = adverts;
    if (!adverts) data = @{};
    [NSKeyedArchiver archiveRootObject:data toFile:adRealTimePath()];
}

/**
 获取历史实时广告数据
 */
+ (NSDictionary<NSString *, NSArray<HYAdvert *> *> * _Nullable)historyRealTimeAdverts {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:adRealTimePath()];
}

/**
 存储已显示实时广告的状态
 */
+ (void)cacheRealTimeAdvertStatus:(NSDictionary<NSString *, NSDictionary<NSString *,NSDictionary<NSString *,HYAdvertStatus *> *> *> *)advertStatus {
    NSDictionary *data = advertStatus;
    if (!advertStatus) data = @{};
    [NSKeyedArchiver archiveRootObject:data toFile:adRealTimeStatusPath()];
}

/**
 获取已显示实时广告的状态
 */
+ (NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary<NSString *,HYAdvertStatus *> *> *> * _Nullable)historyRealTimeAdvertStatus {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:adRealTimeStatusPath()];
}

#pragma mark - Report

/**
 缓存未上报的数据
 */
+ (void)cacheAllReports:(NSArray <NSDictionary *> *)reports {
    NSArray *data = reports;
    if (!reports) data = @[];
    [NSKeyedArchiver archiveRootObject:data toFile:reportsPath()];
}

/**
 返回历史未上报数据
 */
+ (NSArray <NSDictionary *> *)historyReports {
    return [NSKeyedUnarchiver unarchiveObjectWithFile:reportsPath()];
}

@end
