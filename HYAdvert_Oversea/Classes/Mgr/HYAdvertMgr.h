//
//  HYAdvertisementMgr.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/12.
//  Copyright © 2018年 Yvan. All rights reserved.
//

/**
 * 文档链接
 * http://wiki.ihuayue.cn/pages/viewpage.action?pageId=4719841
 * http://wiki.ihuayue.cn/pages/viewpage.action?pageId=4719942
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HYAdvert, HYAdvertThirdSDK, HYAdvertControl;
@interface HYAdvertMgr : NSObject

/**
 启动广告SDK
 
 @brief 启动
 
 @param qid 用户Id, 可为空
 @param u 用户U信息, 可为空
 @param s 用户S信息, 可为空
 @param mcc 请求的地区, 针对海外地区 可为空
 @param userKey 设备唯一标识, UUID
 @param version app的版本号
 @param channel 渠道号
 @param releaseAddress 生成环境地址, 为空, 使用默认地址
 @param debugAddress 测试环境地址, 为空, 使用默认地址
 @param supportAdSource 0.自有渠道 1.第三方渠道 2.gdt , 3. 掌酷(目前只有安卓)  ,4.KA (目前 ios 鲸鱼)
 @param appType (appId) app平台类型 1.鲸鱼小说，2.小书亭，3.坏坏猫 4.海外
 @param isOpenLog 是否开启log
 @param isDebugURL 默认(NO)使用生成环境, YES使用测试环境
 @param isLoadRealTime 是否加载实时广告(又名:第三方广告), 默认为:NO
 */
+ (void)startWithQid:(NSString * _Nullable)qid
                   U:(NSString * _Nullable)u
                   S:(NSString * _Nullable)s
                 mcc:(NSString * _Nullable)mcc
             userKey:(NSString *)userKey
             version:(NSString *)version
             channel:(NSString *)channel
      releaseAddress:(NSString * _Nullable)releaseAddress
        debugAddress:(NSString * _Nullable)debugAddress
     supportAdSource:(NSArray<NSNumber *> *)supportAdSource
             appType:(NSInteger)appType
             openLog:(BOOL)isOpenLog
       usingDebugURL:(BOOL)isDebugURL
        loadRealTime:(BOOL)isLoadRealTime;

/**
 切换账号, 退出登录
 
 @param qid 用户Id, 可为空
 @param u 用户U信息, 可为空
 @param s 用户S信息, 可为空
 */
+ (void)updateQid:(NSString * _Nullable)qid
                U:(NSString * _Nullable)u
                S:(NSString * _Nullable)s;

/// 更新阅读模式 (应付 Facebook 审核)
/// @param readingMode 阅读模式
+ (void)updateReadingMode:(NSInteger)readingMode;

#pragma mark - GetData

/**
 异步获取广告数据
 
 @param pid 广告位id
 @param completion 广告数据模型 -> 图片下载成功才会返回, mainThread
 @param seconds 拉取广告超时时间，区间 (0,10] 秒
 @see 拉取广告位超时时间，在该超时时间内，如果广告拉, 取成功，则立马展示开屏广告，否则放弃此次广告展示机会。
 
 @brief: 1.设置图片, 使用SDWebImage设置即可
 2.设置GIF: UIImageView+HYAdvertGIF, 或者自行从SD中根据URL获取资源, 设置
 3.设置video, 资源的本地路径存储在 advert.filePath
 
 预加载数据, 主动请求一次即可
 
 1.闪屏页 2. 书架页 3. 详情页 4. 内容页 5. 搜索结果页
 6.书城嵌入式插屏,7.书城弹出式插屏广告
 */
+ (void)advertWithAdvertPid:(NSInteger)pid
                 fetchDelay:(NSInteger)seconds
                 completion:(void (^)(HYAdvert * _Nullable advert, NSError * _Nullable error))completion;

/**
 同步获取
 
 @param pid 广告位id
 
 @brief: 1.设置图片, 使用SDWebImage设置即可
 2.设置GIF: UIImageView+HYAdvertGIF, 或者自行从SD中根据URL获取资源, 设置
 3.设置video, 资源的本地路径存储在 advert.filePath
 
 1.闪屏页 2. 书架页 3. 详情页 4. 内容页 5. 搜索结果页
 6.书城嵌入式插屏,7.书城弹出式插屏广告
 
 @return 广告数据模型 -> 图片下载成功才会返回, currentThread
 */
+ (HYAdvert * _Nullable)advertWithAdvertPid:(NSInteger)pid API_DEPRECATED("Do not use this API for dreame!!!", ios(5.0, 8.0));

/**
 第三放SDK配置
 
 @param pid 广告位
 @return HYAdvertThirdSDK
 */
+ (HYAdvertThirdSDK * _Nullable)thirdSDKWithPid:(NSInteger)pid API_DEPRECATED("Do not use this API for dreame!!!", ios(5.0, 8.0));

/**
 相关广告位的控制
 
 @param pid 广告位
 @return HYAdvertControl
 */
+ (HYAdvertControl * _Nullable)advertControlWithPid:(NSInteger)pid API_DEPRECATED("Do not use this API for dreame!!!", ios(5.0, 8.0));

/**
 检查广告位是否展示

 @param advert 广告模型数据
 @return 是否展示i
 */
+ (BOOL)checkAdvert:(HYAdvert *)advert;

#pragma mark - Advert Report

/**
 上报广告显示了
 
 @param advert 广告模型
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportShowAdvert:(HYAdvert *)advert errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被点击了
 
 @param advert 广告模型
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportClickAdvert:(HYAdvert *)advert errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被关闭
 
 @param advert 广告
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportCloseAdvert:(HYAdvert *)advert errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

#pragma mark - ThirdSDK Report

/// 根据adSource 判断使用哪个SDK, 1.4.0版本 adSource = 2 代表广点通
/**
 上报广告显示了
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportShowWithThirdSDK:(HYAdvertThirdSDK *)sdk errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被点击了
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportClickWithThirdSDK:(HYAdvertThirdSDK *)sdk errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

/**
 上报广告被关闭
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportCloseWithThirdSDK:(HYAdvertThirdSDK *)sdk errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

/**
 无广告(第三方sdk)
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportNoAdWithThirdSDK:(HYAdvertThirdSDK *)sdk errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

/**
 加载失败(第三方sdk)
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportLoadFaildWithThirdSDK:(HYAdvertThirdSDK *)sdk errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

/**
 曝光(第三方sdk已经曝光了)
 
 @param sdk HYAdvertThirdSDK
 @param code 错误码
 @param msg 错误信息
 */
+ (void)reportExposuredWithThirdSDK:(HYAdvertThirdSDK *)sdk errorCode:(NSString * _Nullable)code errorMsg:(NSString * _Nullable)msg;

#pragma mark - SDKInfo

/**
 获取广告sdk版本号
 
 @return 版本号
 */
+ (NSString *)sdkVersion;

/**
 获取平台Id
 
 @return 平台Id
 */
+ (NSString *)platform;

+ (dispatch_queue_t)reportQueue;

@end

NS_ASSUME_NONNULL_END

