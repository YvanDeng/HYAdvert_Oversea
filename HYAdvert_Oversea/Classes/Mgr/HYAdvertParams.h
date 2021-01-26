//
//  HYAdvertParams.h
//  AFNetworking
//
//  Created by Yvan on 2018/11/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HYAdvertReportType) { // 上报类型
    HYAdvertReportShow  = 1,
    HYAdvertReportClick = 2,
    HYAdvertReportClose = 3,
    HYAdvertReportSDKNoAd = 4, // SDK无广告
    HYAdvertReportSDKLoadFaild = 5, //SDK加载失败
    HYAdvertReportSDKExposured = 6,//SDK曝光
};

@interface HYAdvertParams : NSObject

/**
 返回基础参数

 @return 基础参数
 */
+ (NSDictionary *)baseParams;

/**
 返回实时请求参数

 @param pid 广告位id
 @return 实时请求参数
 */
+ (NSDictionary *)realTimeParamsWithPid:(NSString *)pid;

/**
 返回上报参数

 @param adId 广告id
 @param adSource 广告来源
 @param pid 广告位
 @param extraData 额外字段, 服务器下发的
 @param code 错误码
 @param msg 错误信息
 @param type 上报类型 HYAdvertReportType
 @return 上报参数
 */
+ (NSDictionary *)reportParamsWithAdId:(NSString * _Nullable)adId
                              adSource:(NSString *)adSource
                                   pid:(NSString *)pid
                             extraData:(NSString * _Nullable)extraData
                             errorCode:(NSString * _Nullable)code
                              errorMsg:(NSString * _Nullable)msg
                                  type:(HYAdvertReportType)type;
@end

NS_ASSUME_NONNULL_END
