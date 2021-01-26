//
//  HYAdvertisementMgr.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/12.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "HYAdvertMgr.h"
#import "HYAdvertRequest.h"
#import "HYAdvertConfig.h"
#import "NSObject+HYUtil.h"
#import "HYAdvertCache.h"
#import "HYAdvert.h"
#import "HYAdvertConfig.h"
#import "HYAdvertReport.h"
#import "HYAdvertStatus.h"
#import "HYAdvertThirdSDK.h"
#import "HYAdvertConstant.h"

static NSString * const HYAdvertRequestQueue = @"com.stary.dreame.HYAdvertRequestQueue";
static NSString * const HYAdvertReportQueue = @"com.stary.dreame.HYAdvertReportQueue";
static NSString * const HYAdvertTimerQueue = @"com.stary.dreame.HYAdvertTimerQueue";

/// 判断资源是否已经下载好了
static BOOL fileExists(HYAdvert *advert) {
    if (advert.showMode == HYAdvertDataTextLoop) return YES;
    
    BOOL exist = YES;
    for (HYAdvertContent *adc in advert.adList) {
        switch (advert.showMode) {
            case HYAdvertDataPic:
            case HYAdvertDataGif:
            case HYAdvertDataPicLoop: {
                // TODO: 推书类型广告(adc.adType == 2) 可以不传 adUrl
                exist &= [HYAdvertCache existImageWithURLStr:adc.adUrl];
            }
                break;
            case HYAdvertDataVideo: {
                // 这里处理有问题
                NSString *filePath = [HYAdvertCache videoPathWithURLStr:adc.adUrl];
                [advert setValue:filePath forKeyPath:@"filePath"];
                exist &= (filePath != nil);
            }
                break;
            default:
                break;
        }
        
        if (!exist) {
            return NO;
        }
    }
    return YES;
}

/// 获取历史实时广告数据
static NSDictionary *historyRealTimeAdverts() {
    NSDictionary *adverts = [HYAdvertCache historyRealTimeAdverts];
    if (!adverts) adverts = @{};
    return adverts;
}

/// 获取历史实时广告数据状态
static NSDictionary *historyRealTimeAdvertStatus() {
    NSDictionary *status = [HYAdvertCache historyRealTimeAdvertStatus];
    if (!status) status = @{};
    return status;
}

/// 缓存实时广告状态
static void cacheRealTimeAdvertStatus(NSDictionary *status) {
    [HYAdvertCache cacheRealTimeAdvertStatus:status];
}

/// 缓存广告状态
static void cacheAdvertStatus(NSDictionary *status) {
    [HYAdvertCache cacheAdvertStatus:status];
}

/// 切换线程
static inline void dispatch_async_advert_mainQueue(void (^block)(void)) {
    [NSThread isMainThread] ? block() : dispatch_async(dispatch_get_main_queue(), block);
}

@interface HYAdvertMgr()
    
// 禁止使用的广告位 pid 集合
@property (nonatomic, copy) NSSet<NSString *> *forBids;
// 广告原始数据，key为pid，value为对应广告位数据
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary *> *results;
// 实时广告数据，key为pid，value为对应的广告位数据。这里由于历史原因，使用了数组，但数组中只有一个元素
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<HYAdvert *> *> *realTimeAdverts;
// 广告数据状态
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary<NSString *, HYAdvertStatus *> *> *> *advertStatus;
// 实时数据状态，这个逻辑比较混乱。原计划一个 status 数据结构存储普通和实时两种广告的状态，当时设计的最外层 key 为 pid，value 对应该广告位普通和实时两种广告的状态 dict；中间层的 key 是 adSouce，对应该广告位普通或实时状态的 dict；最内层的 key 也是 pid，value 对应该广告位真正的 HYAdvertStatus
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary<NSString *, HYAdvertStatus *> *> *> *realTimeStatus;
// 回调映射字典
@property (nonatomic, copy) NSMutableDictionary *callbackMap;
// 是否加载第三方广告
@property (nonatomic, assign) BOOL isLoadRealTime;
    
@end

@implementation HYAdvertMgr {
    dispatch_queue_t _requestQueue;
    dispatch_queue_t _reportQueue;
    dispatch_queue_t _timerQueue;
    dispatch_semaphore_t _lock;
    dispatch_semaphore_t _resultLock;
}
    
+ (instancetype)sharedInstance {
    static HYAdvertMgr *_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[[self class] alloc] init];
    });
    return _manager;
}
    
- (instancetype)init {
    if (self = [super init]) {
        _requestQueue = dispatch_queue_create(HYAdvertRequestQueue.UTF8String, DISPATCH_QUEUE_SERIAL);
        _reportQueue = dispatch_queue_create(HYAdvertReportQueue.UTF8String, DISPATCH_QUEUE_CONCURRENT);
        _timerQueue = dispatch_queue_create(HYAdvertTimerQueue.UTF8String, DISPATCH_QUEUE_CONCURRENT);
        _lock = dispatch_semaphore_create(1);
        _resultLock = dispatch_semaphore_create(1);
        _callbackMap = @{}.mutableCopy;
    }
    return self;
}

#pragma mark - Config
    
+ (void)startWithQid:(NSString *)qid
                   U:(NSString *)u
                   S:(NSString *)s
                 mcc:(NSString * _Nullable)mcc
             userKey:(NSString * _Nonnull)userKey
             version:(NSString * _Nonnull)version
             channel:(NSString * _Nonnull)channel
      releaseAddress:(NSString * _Nullable)releaseAddress
        debugAddress:(NSString * _Nullable)debugAddress
     supportAdSource:(NSArray<NSNumber *> *)supportAdSource
             appType:(NSInteger)appType
             openLog:(BOOL)isOpenLog
       usingDebugURL:(BOOL)isDebugURL
        loadRealTime:(BOOL)isLoadRealTime {
    
    /// 第一次升级至1.5.10，清理历史缓存
    if ([[HYAdvertConfig sdkVersion] isEqualToString:@"1.5.10"]) {
        [HYAdvertCache clearAllCachesWithSDKVersion:[HYAdvertConfig sdkVersion]];
    }
    
    /// 环境配置
    if (releaseAddress) {
        [HYAdvertConfig setReleaseAddress:releaseAddress];
    }
    if (debugAddress) {
        [HYAdvertConfig setDebugAddress:debugAddress];
    }
    
    /// 日志 && 环境
    [HYAdvertConfig setLogEnable:isOpenLog];
    [HYAdvertConfig setDebugEnv:isDebugURL];
    
    /// 设置基础参数
    [HYAdvertConfig setU:u];
    [HYAdvertConfig setS:s];
    [HYAdvertConfig setQid:qid];
    [HYAdvertConfig setMcc:mcc];
    [HYAdvertConfig setUserKey:userKey];
    [HYAdvertConfig setVersion:version];
    [HYAdvertConfig setChannel:channel];
    [HYAdvertConfig setAppType:appType];
    [HYAdvertConfig setSupportAdSource:supportAdSource];
    
    // 管理
    [HYAdvertMgr sharedInstance].isLoadRealTime = isLoadRealTime;
    /// 请求广告配置
//    [[HYAdvertMgr sharedInstance] getAdverts];
}

+ (void)updateQid:(NSString *)qid
                U:(NSString *)u
                S:(NSString *)s {
    [HYAdvertConfig setU:u];
    [HYAdvertConfig setS:s];
    [HYAdvertConfig setQid:qid];
    
    [[HYAdvertMgr sharedInstance] getAdverts];
}

+ (void)updateReadingMode:(NSInteger)readingMode {
    [HYAdvertConfig setReadingMode:readingMode];
}

/// 请求新的广告数据
- (void)getAdverts {
    dispatch_async([HYAdvertMgr sharedInstance]->_requestQueue, ^{
        dispatch_semaphore_wait([HYAdvertMgr sharedInstance]->_lock, DISPATCH_TIME_FOREVER);
        __weak typeof(self)weakSelf = self;
        [HYAdvertRequest getAdvertsWithLocal:^(NSDictionary *results, NSDictionary *advertStatus) {
            // 本地回调
            __strong typeof(weakSelf)strongSelf = weakSelf;
            strongSelf.results = results;
            strongSelf.advertStatus = advertStatus;
            
        } netWork:^(NSDictionary *results, NSDictionary *advertStatus) {
            // 网络回调, 解锁
            __strong typeof(weakSelf)strongSelf = weakSelf;
            dispatch_semaphore_signal(strongSelf->_lock);
            strongSelf.results = results;
            strongSelf.advertStatus = advertStatus;
            
        } failure:^(NSString *error) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            dispatch_semaphore_signal(strongSelf->_lock);
            HYAdvertLog(@"请求广告数据出错 -- %@", error);
        }];
    });
}

#pragma mark - GetAdvert
    
/// 异步拉取回调
+ (void)cancelTimer:(dispatch_source_t)timer
                pid:(NSString *)pid
             advert:(HYAdvert * _Nullable)advert
              error:(NSError * _Nullable)error
          isTimeout:(BOOL)timeout {
    if (timer) {
        dispatch_source_cancel(timer);
        timer = nil;
    }
    dispatch_async_advert_mainQueue(^{
        void(^callback)(HYAdvert * _Nullable, NSError * _Nullable) = [HYAdvertMgr sharedInstance].callbackMap[pid];
        if (callback) {
            if (timeout) {
                NSError *timeoutError = [NSError errorWithDomain:@"HYAdvertErrorDomain" code:HYAdvertErrorBusinessTimeout userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"HYAdvert for pid(%@) has been time out!", pid]}];
                callback(advert, timeoutError);
            } else {
                callback(advert, error);
            }
            [HYAdvertMgr sharedInstance].callbackMap[pid] = nil;
        }
    });
}

/// 异步获取广告位数据
+ (void)advertWithAdvertPid:(NSInteger)pid fetchDelay:(NSInteger)seconds completion:(void (^)(HYAdvert * _Nullable, NSError * _Nullable))completion {
    NSAssert([NSThread isMainThread], @"(+advertWithAdvertPid) must be call on main thread.");
    
    NSString *pidStr = [NSString stringWithFormat:@"%zd", pid];
    HYAdvertMgr *mgr = [HYAdvertMgr sharedInstance];
    
    // 广告位禁止使用，单次启动
    if ([mgr.forBids containsObject:pidStr]) {
        dispatch_async_advert_mainQueue(^{
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"HYAdvertErrorDomain" code:HYAdvertErrorForbidden userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"HYAdvert for pid(%@) has been forbbiden!", pidStr]}];
                completion(nil, error);
            }
        });
        return;
    }
    
    // 编译器会自动执行拷贝操作，拷贝栈block到堆上，自己管理block生命周期
    void(^completionCopy)(HYAdvert * _Nullable, NSError *) = completion;
    [HYAdvertMgr sharedInstance].callbackMap[pidStr] = completionCopy;
    
    // 异步串行队列，注意：队列一定要是全局变量，否则每次执行开辟一条新线程
    dispatch_async([HYAdvertMgr sharedInstance]->_requestQueue, ^{
        // 自定义业务超时
        NSInteger time = seconds;
        if (time <= 0) time = 0;
        if (time > 10) time = 10;
        dispatch_source_t timer = nil;
        if (time > 0) {
            timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [HYAdvertMgr sharedInstance]->_timerQueue);
            dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC), time * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
            dispatch_source_set_event_handler(timer, ^{
                // 业务超时回调
                [self cancelTimer:timer pid:pidStr advert:nil error:nil isTimeout:YES];
            });
            dispatch_resume(timer);
        }
        
        // 请求锁
        dispatch_semaphore_wait(mgr->_lock, DISPATCH_TIME_FOREVER);
        
        // TODO: 这里是否需要使用缓存
        
        // 调用接口实时获取广告
        [HYAdvertRequest getByRealTimeAdvertWithPid:pidStr completion:^(NSDictionary *adverts, NSDictionary *advertStatus, NSDictionary *results, NSError *error) {
            // 响应锁
            dispatch_semaphore_wait(mgr->_resultLock, DISPATCH_TIME_FOREVER);
            
            // 请求发生错误 (包含图片资源未下载成功的场景)
            if (error) {
                [self cancelTimer:timer pid:pidStr advert:nil error:error isTimeout:NO];
                // 释放锁
                dispatch_semaphore_signal(mgr->_resultLock);
                
                return;
            }
            
            // 存储请求结果
            mgr.realTimeAdverts = adverts;
            mgr.realTimeStatus = advertStatus;
            if (results) {
                mgr.results = results;
            }
            
            // 检查广告位有效展示时间与有效展示次数逻辑（网络回调时文件已经写入，因此这里不检查文件是否已写入完毕）
            HYAdvert *advert = [mgr checkAdverts:adverts[pidStr] sourceStatus:advertStatus[pidStr] shouldCheckFile:NO];
            if (advert) {
                // 检查广告位的展示规则逻辑
                NSDictionary *sourceStatus = advertStatus[advert.adSource];
                HYAdvertStatus *advertStatus = sourceStatus[advert.pid];
                if (!dateFormatter) dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd"];
                NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
                // 当天禁止展示
                if (advert.closeLogic == 2 && [advertStatus.closedDic[dateString] boolValue]) {
                    NSError *error = [NSError errorWithDomain:@"HYAdvertErrorDomain" code:HYAdvertErrorForbidden userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"HYAdvert for pid(%@) has been forbbiden today!", pidStr]}];
                    [self cancelTimer:timer pid:pidStr advert:nil error:error isTimeout:NO];
                    // 释放锁
                    dispatch_semaphore_signal(mgr->_resultLock);
                    
                    return;
                }
            }
            
            // 正常回调
            [self cancelTimer:timer pid:pidStr advert:advert error:nil isTimeout:NO];
            // 释放锁
            dispatch_semaphore_signal(mgr->_resultLock);
        }];
        // 并发请求，每个request的http头部SIGN字段不一样，需要调用完接口再释放信号
        dispatch_semaphore_signal(mgr->_lock);
    });
}

/// 同步获取广告位数据, 此接口未更新禁用
+ (HYAdvert *)advertWithAdvertPid:(NSInteger)pidKey {
    NSString *pid = [NSString stringWithFormat:@"%zd", pidKey];
    HYAdvertMgr *mgr = [HYAdvertMgr sharedInstance];
    if ([mgr.forBids containsObject:pid]) return nil;
    
    NSDictionary *pidDict = mgr.results[pid];
    NSArray *adverts = pidDict[@"item"];
    NSDictionary *sourceStatus = [mgr advertStatus][pid];
    /// 优先获取广告数据
    id advert = [mgr checkAdverts:adverts sourceStatus:sourceStatus shouldCheckFile:YES];
    if (advert) return advert;
    
    // 获取实时广告数据
    mgr.realTimeAdverts = historyRealTimeAdverts();
    mgr.realTimeStatus = historyRealTimeAdvertStatus();
    return [mgr checkAdverts:mgr.realTimeAdverts[pid]
                sourceStatus:mgr.realTimeStatus[pid]
             shouldCheckFile:YES];
}

/// 检测数据合法数据
- (HYAdvert *)checkAdverts:(NSArray<HYAdvert *> *)adverts sourceStatus:(NSDictionary *)sourceStatus shouldCheckFile:(BOOL)checkFile {
    if (!adverts) return nil;
    
    /// 排序: 优先级高, 显示时间小
    NSArray *sortArray = [adverts sortedArrayUsingComparator:^NSComparisonResult(HYAdvert *  _Nonnull obj1, HYAdvert *  _Nonnull obj2) {
        if (obj1.priority == obj2.priority) { // 相同优先级, 判断
            
            NSDictionary *advertStatus1 = sourceStatus[obj1.adSource];
            NSDictionary *advertStatus2 = sourceStatus[obj2.adSource];
            
            HYAdvertStatus *status1 = advertStatus1[obj1.adId];
            HYAdvertStatus *status2 = advertStatus2[obj2.adId];
            
            NSComparisonResult result = NSOrderedAscending;
            if (!status1) result = NSOrderedAscending;
            if (!status2) result = NSOrderedDescending;
            if (status1.showTime > status2.showTime) { // 优先显示时间小的
                result = NSOrderedDescending;
            }
            return result;
            
        }
        return obj1.priority < obj2.priority; // 优先级高
    }];
    
    NSTimeInterval curTime = [NSDate hy_currentTime];
    for (HYAdvert *advert in sortArray) {
        // 先查找优先级高的, 显示时间小的
        if (curTime <= advert.endTime && advert.startTime <= curTime) { // 展示时间范围内
            NSDictionary *advertStatus = sourceStatus[advert.adSource];
            HYAdvertStatus *status = advertStatus[advert.pid];
            BOOL isShow = [self checkAdvert:advert status:status shouldCheckFile:checkFile];
            if (isShow) return [advert copy];
        }
    }
    return nil;
}

/// 检测单个数据是否有效
- (BOOL)checkAdvert:(HYAdvert *)advert status:(HYAdvertStatus *)status shouldCheckFile:(BOOL)checkFile {
    if (!advert) return NO;
    if (status) { // 本地有advertStatus
        if (status.showCount >= advert.showCount) return NO; // 展示次数过多
        
        BOOL isSameDay = [NSDate hy_isSameDayWithTimeInterval:status.showTime];
        if (isSameDay) {
            // 同一天
            if (status.showCountDaily >= advert.showCountDaily) return NO; // 当天的展示次数过多
        }
        if (checkFile) return fileExists(advert); // 资源是否已下载
        return YES;
    } else { // 本地无advertStatus
        if (advert.showCount <= advert.hasShowedCount) return NO; // 展示次数过多
        if (checkFile) return fileExists(advert); // 资源是否已下载
        return YES;
    }
}

+ (BOOL)checkAdvert:(HYAdvert *)advert {
    if (!advert) return NO;
    NSDictionary *sourceStatus = [HYAdvertMgr sharedInstance].realTimeStatus[advert.pid];
    NSTimeInterval curTime = [NSDate hy_currentTime];
    if (curTime <= advert.endTime && advert.startTime <= curTime) { // 展示时间范围内
        NSDictionary *advertStatus = sourceStatus[advert.adSource];
//        HYAdvertStatus *status = advertStatus[advert.adId];
        HYAdvertStatus *status = advertStatus[advert.pid];
        return [[HYAdvertMgr sharedInstance] checkAdvert:advert status:status shouldCheckFile:YES];
    }
    return NO;
}

+ (HYAdvertThirdSDK * _Nullable)thirdSDKWithPid:(NSInteger)pidKey {
    NSString *pid = [NSString stringWithFormat:@"%zd", pidKey];
    HYAdvertMgr *mgr = [HYAdvertMgr sharedInstance];
    if ([mgr.forBids containsObject:pid]) return nil;
    NSDictionary *pidDict = [HYAdvertMgr sharedInstance].results[pid];
    return pidDict[@"sdk"];
}

+ (HYAdvertControl * _Nullable)advertControlWithPid:(NSInteger)pidKey {
    NSString *pid = [NSString stringWithFormat:@"%zd", pidKey];
    NSDictionary *pidDict = [HYAdvertMgr sharedInstance].results[pid];
    return pidDict[@"config"];
}

#pragma mark - Advert Report

/// 显示了广告
+ (void)reportShowAdvert:(HYAdvert *)advert
               errorCode:(NSString * _Nullable)code
                errorMsg:(NSString *)msg {
    if (!advert) return;
    
    dispatch_async([HYAdvertMgr sharedInstance]->_requestQueue, ^{
        dispatch_semaphore_wait([HYAdvertMgr sharedInstance]->_lock, DISPATCH_TIME_FOREVER);
        /// 获取status
        NSDictionary *advertStatus = nil;
        if (advert.sourceType == HYAdvertSourceNormal) {
            /// 创建/更新 HYAdvertStatus
            advertStatus = [HYAdvertMgr sharedInstance].advertStatus[advert.pid];
        } else if (advert.sourceType == HYAdvertSourceRealTime) {
            /// 创建/更新 HYAdvertStatus
            advertStatus = [HYAdvertMgr sharedInstance].realTimeStatus[advert.pid];
        }
        
        NSDictionary *sourceStatus = advertStatus[advert.adSource];
        HYAdvertStatus *status = sourceStatus[advert.pid];
        status? updateStatus(advert, advert.sourceType) : newStatus(advert, advert.sourceType);
        
        dispatch_semaphore_signal([HYAdvertMgr sharedInstance]->_lock);
    });
    /// 上报
    [HYAdvertReport reportShowAdvert:advert errorCode:code errorMsg:msg];
}

/// 点击了广告
+ (void)reportClickAdvert:(HYAdvert *)advert
                errorCode:(NSString * _Nullable)code
                 errorMsg:(NSString *)msg {
    if (!advert) return;
    [HYAdvertReport reportClickAdvert:advert errorCode:code errorMsg:msg];
}

/// 关闭广告位
+ (void)reportCloseAdvert:(HYAdvert *)advert
                errorCode:(NSString * _Nullable)code
                 errorMsg:(NSString *)msg {
    if (!advert) return;
    if (advert.closeLogic == 1) {
        // 禁止广告位，单次启动
        forBidPid(advert.pid);
    }
    // 记录关闭状态
    updateRealTimeClosedStatus(advert, YES);
    /// 上报
    [HYAdvertReport reportCloseAdvert:advert errorCode:code errorMsg:msg];
}

#pragma mark - ThirdSDK Report

+ (void)reportShowWithThirdSDK:(HYAdvertThirdSDK *)sdk
                     errorCode:(NSString * _Nullable)code
                      errorMsg:(NSString *)msg {
    if (!sdk) return;
    [HYAdvertReport reportShowWithThirdSDK:sdk errorCode:code errorMsg:msg];
}

+ (void)reportClickWithThirdSDK:(HYAdvertThirdSDK *)sdk
                      errorCode:(NSString * _Nullable)code
                       errorMsg:(NSString *)msg {
    if (!sdk) return;
    [HYAdvertReport reportClickWithThirdSDK:sdk errorCode:code errorMsg:msg];
}

+ (void)reportCloseWithThirdSDK:(HYAdvertThirdSDK *)sdk
                      errorCode:(NSString * _Nullable)code
                       errorMsg:(NSString *)msg {
    if (!sdk) return;
    /// 禁止广告位
    forBidPid(sdk.pid);
    /// 上报
    [HYAdvertReport reportCloseWithThirdSDK:sdk errorCode:code errorMsg:msg];
}

+ (void)reportNoAdWithThirdSDK:(HYAdvertThirdSDK *)sdk
                     errorCode:(NSString * _Nullable)code
                      errorMsg:(NSString *)msg {
    if (!sdk) return;
    [HYAdvertReport reportNoAdWithThirdSDK:sdk errorCode:code errorMsg:msg];
}

+ (void)reportLoadFaildWithThirdSDK:(HYAdvertThirdSDK *)sdk
                          errorCode:(NSString * _Nullable)code
                           errorMsg:(NSString *)msg {
    if (!sdk) return;
    [HYAdvertReport reportLoadFaildWithThirdSDK:sdk errorCode:code errorMsg:msg];
}

+ (void)reportExposuredWithThirdSDK:(HYAdvertThirdSDK * _Nonnull)sdk
                          errorCode:(NSString * _Nullable)code
                           errorMsg:(NSString * _Nullable)msg {
    if (!sdk) return;
    [HYAdvertReport reportExposuredWithThirdSDK:sdk errorCode:code errorMsg:msg];
}

#pragma mark - func

/// 禁止广告位
static void forBidPid(NSString *pid) {
    /// 添加进禁止集合
    NSMutableSet *borbids = [[HYAdvertMgr sharedInstance].forBids mutableCopy];
    if (!borbids) borbids = [NSMutableSet set];
    [borbids addObject:pid];
    [HYAdvertMgr sharedInstance].forBids = [borbids copy];
}

/// 新建
static void newStatus(HYAdvert *advert, HYAdvertSourceType soucrceType) {
    NSMutableDictionary *newStatus = nil;
    if (soucrceType == HYAdvertSourceNormal) {
        newStatus = [[HYAdvertMgr sharedInstance].advertStatus mutableCopy];
    } else if (soucrceType == HYAdvertSourceRealTime) {
        newStatus = [[HYAdvertMgr sharedInstance].realTimeStatus mutableCopy];
    }
    
    if (!newStatus) newStatus = @{}.mutableCopy;
    
    NSMutableDictionary *advertStatus = [newStatus[advert.pid] mutableCopy];
    if (!advertStatus) advertStatus = @{}.mutableCopy;
    
    NSMutableDictionary *sourceStatus = [advertStatus[advert.adSource] mutableCopy];
    if (!sourceStatus) sourceStatus = @{}.mutableCopy;
    
    /// 初始化
    HYAdvertStatus *status = [HYAdvertStatus statusWithPid:advert.pid];
    sourceStatus[advert.pid] = [status copy];
    advertStatus[advert.adSource] = [sourceStatus copy];
    newStatus[advert.pid] = [advertStatus copy];
    NSDictionary *updateStatus = [newStatus copy];
    
    if (soucrceType == HYAdvertSourceNormal) {
        [HYAdvertMgr sharedInstance].advertStatus = updateStatus;
        cacheAdvertStatus(updateStatus);
    } else if (soucrceType == HYAdvertSourceRealTime) {
        [HYAdvertMgr sharedInstance].realTimeStatus = updateStatus;
        cacheRealTimeAdvertStatus(updateStatus);
    }
}

/// 更新
static void updateStatus(HYAdvert *advert, HYAdvertSourceType soucrceType) {
    NSMutableDictionary *newStatus = nil;
    if (soucrceType == HYAdvertSourceNormal) {
        newStatus = [[HYAdvertMgr sharedInstance].advertStatus mutableCopy];
    } else if (soucrceType == HYAdvertSourceRealTime) {
        newStatus = [[HYAdvertMgr sharedInstance].realTimeStatus mutableCopy];
    }
    
    NSMutableDictionary *advertStatus = [newStatus[advert.pid] mutableCopy];
    NSMutableDictionary *sourceStatus = [advertStatus[advert.adSource] mutableCopy];
    HYAdvertStatus *status = sourceStatus[advert.pid];
    
    /// 赋新值
    [status updateStatus];
    sourceStatus[advert.pid] = [status copy];
    advertStatus[advert.adSource] = [sourceStatus copy];
    newStatus[advert.pid] = [advertStatus copy];
    NSDictionary *updateStatus = [newStatus copy];
    
    if (soucrceType == HYAdvertSourceNormal) {
        [HYAdvertMgr sharedInstance].advertStatus = updateStatus;
        cacheAdvertStatus(updateStatus);
    } else if (soucrceType == HYAdvertSourceRealTime) {
        [HYAdvertMgr sharedInstance].realTimeStatus = updateStatus;
        cacheRealTimeAdvertStatus(updateStatus);
    }
}

// 更新关闭逻辑
static NSDateFormatter *dateFormatter = nil;

static void updateRealTimeClosedStatus(HYAdvert *advert, BOOL hasClosedForToday) {
    NSMutableDictionary *newStatus = [[HYAdvertMgr sharedInstance].realTimeStatus mutableCopy];
    
    NSMutableDictionary *advertStatus = [newStatus[advert.pid] mutableCopy];
    NSMutableDictionary *sourceStatus = [advertStatus[advert.adSource] mutableCopy];
    HYAdvertStatus *status = sourceStatus[advert.pid];
    
    if (!dateFormatter) dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    BOOL closed = [status.closedDic[dateString] boolValue];
    if (closed == hasClosedForToday) return;
    
    NSMutableDictionary *closedDic = [status.closedDic mutableCopy];
    if (!closedDic) closedDic = @{}.mutableCopy;
    
    /// 赋新值
    closedDic[dateString] = @(hasClosedForToday);
    status.closedDic = [closedDic copy];
    sourceStatus[advert.pid] = [status copy];
    advertStatus[advert.adSource] = [sourceStatus copy];
    newStatus[advert.pid] = [advertStatus copy];
    NSDictionary *updateStatus = [newStatus copy];
    
    [HYAdvertMgr sharedInstance].realTimeStatus = updateStatus;
    cacheRealTimeAdvertStatus(updateStatus);
}

#pragma mark - Getter
    
+ (NSString *)sdkVersion {
    return [HYAdvertConfig sdkVersion];
}
    
+ (NSString *)platform {
    return [HYAdvertConfig platform];
}

+ (dispatch_queue_t)reportQueue {
    return [HYAdvertMgr sharedInstance]->_reportQueue;
}
    
@end

