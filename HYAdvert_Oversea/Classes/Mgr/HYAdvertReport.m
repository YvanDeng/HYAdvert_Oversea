//
//  HYAdvertReport.m
//  AFNetworking
//
//  Created by Yvan on 2018/11/27.
//

#import "HYAdvertReport.h"
#import "HYHttpMgr.h"
#import "HYAdvertMgr.h"
#import "NSObject+HYUtil.h"
#import "HYAdvertConfig.h"
#import "HYAdvertCache.h"
#import "HYAdvertParams.h"
#import "HYAdvertThirdSDK.h"
#import "HYAdvert.h"

@implementation HYAdvertReport

/// 未上报/上报失败的数据
static NSArray<NSDictionary *> *allReports;
static BOOL isReporting = NO;

#pragma mark - Cache
// ---------------上报---------------------------//
/// 获取历史未上报成功数据
static NSArray *historyReports() {
    NSArray *reports = [HYAdvertCache historyReports];
    if (!reports) reports = @[];
    return reports;
}

/// 缓存上报数据
static void cacheReports(NSArray *reports) {
    [HYAdvertCache cacheAllReports:reports];
}

/// 最多上报10个数据
static const NSUInteger maxReportCount = 10;
static NSArray *subArray(NSArray *array) {
    return [array subarrayWithRange:NSMakeRange(0, maxReportCount)];
}

NSUInteger reportRetryCount = 3;
#pragma mark - Advert Report

+ (void)reportShowAdvert:(HYAdvert * _Nonnull)advert
               errorCode:(NSString * _Nullable)code
                errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:advert.adId
                        adSource:advert.adSource
                             pid:advert.pid
                       extraData:advert.extraData
                       errorCode:code errorMsg:msg
                            type:HYAdvertReportShow];
}

+ (void)reportClickAdvert:(HYAdvert * _Nonnull)advert
                errorCode:(NSString * _Nullable)code
                 errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:advert.adId
                        adSource:advert.adSource
                             pid:advert.pid
                       extraData:advert.extraData
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportClick];
}

+ (void)reportCloseAdvert:(HYAdvert * _Nonnull)advert
                errorCode:(NSString * _Nullable)code
                 errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:advert.adId
                        adSource:advert.adSource
                             pid:advert.pid
                       extraData:advert.extraData
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportClose];
}

#pragma mark - ThirdSDK Report

+ (void)reportShowWithThirdSDK:(HYAdvertThirdSDK * _Nonnull)sdk
                     errorCode:(NSString * _Nullable)code
                      errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:nil
                        adSource:sdk.adSource
                             pid:sdk.pid
                       extraData:nil
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportShow];
}

+ (void)reportClickWithThirdSDK:(HYAdvertThirdSDK * _Nonnull)sdk
                      errorCode:(NSString * _Nullable)code
                       errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:nil
                        adSource:sdk.adSource
                             pid:sdk.pid
                       extraData:nil
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportClick];
}

+ (void)reportCloseWithThirdSDK:(HYAdvertThirdSDK * _Nonnull)sdk
                      errorCode:(NSString * _Nullable)code
                       errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:nil
                        adSource:sdk.adSource
                             pid:sdk.pid
                       extraData:nil
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportClose];
}

+ (void)reportNoAdWithThirdSDK:(HYAdvertThirdSDK * _Nonnull)sdk
                     errorCode:(NSString * _Nullable)code
                      errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:nil
                        adSource:sdk.adSource
                             pid:sdk.pid
                       extraData:nil
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportSDKNoAd];
}

+ (void)reportLoadFaildWithThirdSDK:(HYAdvertThirdSDK * _Nonnull)sdk
                          errorCode:(NSString * _Nullable)code
                           errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:nil
                        adSource:sdk.adSource
                             pid:sdk.pid
                       extraData:nil
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportSDKLoadFaild];
}

+ (void)reportExposuredWithThirdSDK:(HYAdvertThirdSDK * _Nonnull)sdk
                          errorCode:(NSString * _Nullable)code
                           errorMsg:(NSString * _Nullable)msg {
    [self postReportWithWithAdId:nil
                        adSource:sdk.adSource
                             pid:sdk.pid
                       extraData:nil
                       errorCode:code
                        errorMsg:msg
                            type:HYAdvertReportSDKExposured];
}

/// 上报
static NSMutableArray<NSDictionary *> *getReports() {
    NSMutableArray *reports = [allReports mutableCopy]; // 内存
    if (!reports) reports = historyReports().mutableCopy; // 沙盒
    return reports;
}

+ (void)postHistoryReports {
    dispatch_async([HYAdvertMgr reportQueue], ^{
        allReports = [getReports() copy];
        [self sendAllReport];
    });
}

+ (void)postReportWithWithAdId:(NSString * _Nullable)adId
                      adSource:(NSString * _Nonnull)adSource
                           pid:(NSString * _Nonnull)pid
                     extraData:(NSString * _Nullable)extraData
                     errorCode:(NSString * _Nullable)code
                      errorMsg:(NSString *_Nullable)msg
                          type:(HYAdvertReportType)type {
    /// 队列控制
    dispatch_async([HYAdvertMgr reportQueue], ^{
        NSDictionary *newReportParams = [HYAdvertParams reportParamsWithAdId:adId adSource:adSource pid:pid extraData:extraData errorCode:code errorMsg:msg type:type];
        NSMutableArray *reports = getReports();
        [reports addObject:newReportParams]; // 合并数据
        allReports = [reports copy]; // 存储
        cacheReports(reports.copy); // 缓存
        
        [self sendAllReport]; // 上报
    });
}

+ (void)sendAllReport {
    if (isReporting) return;
    NSArray *reports = allReports;
    if (reports.count > maxReportCount) {
        isReporting = YES;
        NSArray *sendReports = subArray(reports);
        [self sendReport:sendReports];
    } else if (reports.count > 0) {
        isReporting = YES;
        [self sendReport:reports];
    } else {
        isReporting = NO;
    }
}

+ (void)sendReport:(NSArray *)reports {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *baseParams = [HYAdvertParams baseParams];
    params[@"a"] = baseParams;
    params[@"b"] = reports;
    
    [[HYHttpMgr manager] postWithURL:@"/report" params:[params copy] success:^(id response) {
        /// 移除
        NSMutableArray *newAllReports = [allReports mutableCopy];
        [newAllReports removeObjectsInArray:reports];
        allReports = [newAllReports copy];
         /// 队列控制, 删除已经上报了的
        cacheReports(allReports);
        /// 继续上报
        isReporting = NO;
        [self sendAllReport];
        reportRetryCount = 3;
        
    } failure:^(NSError *error) {
        if (reportRetryCount > 0) {
            reportRetryCount --;
            isReporting = NO;
            [self sendAllReport];
        }
    }];
}

@end
