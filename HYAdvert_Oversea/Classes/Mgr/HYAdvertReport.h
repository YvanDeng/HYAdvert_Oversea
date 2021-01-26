//
//  HYAdvertReport.h
//  AFNetworking
//
//  Created by Yvan on 2018/11/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HYAdvert, HYAdvertThirdSDK;
@interface HYAdvertReport : NSObject

#pragma mark - Advert Report

/**
 上报所有历史数据
 */
+ (void)postHistoryReports;

/**
 上报广告显示了
 
 @param advert 广告模型
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportShowAdvert:(HYAdvert *)advert
               errorCode:(NSString * _Nullable)code
                errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被点击了
 
 @param advert 广告模型
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportClickAdvert:(HYAdvert *)advert
                errorCode:(NSString * _Nullable)code
                 errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被关闭
 
 @param advert 广告
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportCloseAdvert:(HYAdvert *)advert
                errorCode:(NSString * _Nullable)code
                 errorMsg:(NSString * _Nullable)msg;

#pragma mark - ThirdSDK Report

/**
 上报广告显示了
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportShowWithThirdSDK:(HYAdvertThirdSDK *)sdk
                     errorCode:(NSString * _Nullable)code
                      errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被点击了
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportClickWithThirdSDK:(HYAdvertThirdSDK *)sdk
                      errorCode:(NSString * _Nullable)code
                       errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被关闭
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportCloseWithThirdSDK:(HYAdvertThirdSDK *)sdk
                      errorCode:(NSString * _Nullable)code
                       errorMsg:(NSString * _Nullable)msg;

/**
 无广告(第三方sdk)
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportNoAdWithThirdSDK:(HYAdvertThirdSDK *)sdk
                     errorCode:(NSString * _Nullable)code
                      errorMsg:(NSString * _Nullable)msg;

/**
 加载失败(第三方sdk)
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportLoadFaildWithThirdSDK:(HYAdvertThirdSDK *)sdk
                          errorCode:(NSString * _Nullable)code
                           errorMsg:(NSString * _Nullable)msg;

/**
 曝光(第三方sdk已经曝光了)
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportExposuredWithThirdSDK:(HYAdvertThirdSDK *)sdk
                          errorCode:(NSString * _Nullable)code
                           errorMsg:(NSString * _Nullable)msg;

@end

NS_ASSUME_NONNULL_END
