//
//  HYAdvertCache.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/14.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HYAdvert, HYAdvertStatus;
@interface HYAdvertCache : NSObject

+ (void)clearAllCachesWithSDKVersion:(NSString *)sdkVersion;

/**
 存储广告数据
 */
+ (void)cacheAdverts:(NSDictionary *)adverts;

/**
 获取历史广告数据
 */
+ (NSDictionary * _Nullable)historyAdverts;

/**
 存储已显示广告的状态
 */
+ (void)cacheAdvertStatus:(NSDictionary<NSString *, NSDictionary<NSString *,NSDictionary<NSString *,HYAdvertStatus *> *> *> *)advertStatus;

/**
 获取已显示广告的状态
 */
+ (NSDictionary<NSString *, NSDictionary<NSString *,NSDictionary<NSString *,HYAdvertStatus *> *> *> * _Nullable)historyAdvertStatus;

#pragma mark - RealTime AD

/**
 存储实时广告数据
 */
+ (void)cacheRealTimeAdverts:(NSDictionary<NSString *, NSArray<HYAdvert *> *> *)adverts;

/**
 获取历史实时h广告数据
 */
+ (NSDictionary<NSString *,NSArray<HYAdvert *> *> * _Nullable)historyRealTimeAdverts;

/**
 存储已显示实时广告的状态
 */
+ (void)cacheRealTimeAdvertStatus:(NSDictionary<NSString *, NSDictionary<NSString *,NSDictionary<NSString *,HYAdvertStatus *> *> *> * _Nonnull)advertStatus;

/**
 获取已显示实时广告的状态
 */
+ (NSDictionary<NSString *, NSDictionary<NSString *,NSDictionary<NSString *,HYAdvertStatus *> *> *> * _Nullable)historyRealTimeAdvertStatus;

#pragma mark - Report

/**
 缓存未上报的数据
 */
+ (void)cacheAllReports:(NSArray <NSDictionary *> * _Nullable)reports;

/**
 返回历史未上报数据
 */
+ (NSArray <NSDictionary *> * _Nullable)historyReports;

/**
 检测图片是否已经缓存

 @param urlStr 图片链接
 @return YES/NO
 */
+ (BOOL)existImageWithURLStr:(NSString *)urlStr;

/**
 检测视频是否已经缓存
 
 @param urlStr 视频链接
 @return 本地缓存路劲
 */
+ (NSString * _Nullable)videoPathWithURLStr:(NSString *)urlStr;

/**
  下载图片

 @param urls 图片链接
 */
+ (void)downLoadImageWithURLs:(NSArray<NSURL *> *)urls;

/**
 下载视频
 
 @param URLStrs 视频链接
 */
+ (void)downVideosWithURLStrs:(NSArray<NSString *> *)URLStrs;

/**
 实时下载

 @param imageURLs 图片资源
 @param videosURLStrs 视频资源
 @param completion 结束 不考虑成功/失败
 */
+ (void)downLoadingWithImageURLs:(NSArray<NSURL *> *)imageURLs videosURLStrs:(NSArray<NSString *> *)videosURLStrs completion:(void(^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
