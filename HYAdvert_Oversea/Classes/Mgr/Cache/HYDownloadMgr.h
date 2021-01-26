//
//  HYDownloadMgr.h
//  AFNetworking
//
//  Created by Yvan on 2018/11/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 后期在扩展

@interface HYDownloadMgr : NSObject

+ (instancetype)manager;

/**
 key: URLString
 */
- (NSString * _Nullable)fileExsitsWithKey:(NSString *)URLStr;

/**
 NSURLSessionDownloadTask == nil, 说明已经存在此文件
 */
- (NSURLSessionDownloadTask  * _Nullable )downloadWithURLStr:(NSString *)URLStr completion:(nullable void(^)(void))completion;

/**
 批量下载

 @param URLStrs 链接s
 */
- (void)downloadWithURLStrs:(NSArray<NSString *> *)URLStrs;

/**
 缓存视频元数据

 @param URLStrs 链接s
 */
- (void)cacheVideosMetaDataWithURLStrs:(NSArray<NSString *> *)URLStrs;

@end

NS_ASSUME_NONNULL_END
