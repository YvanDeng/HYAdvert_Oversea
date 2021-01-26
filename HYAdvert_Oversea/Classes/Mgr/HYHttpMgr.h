//
//  HYHttpMgr.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HYHttpRequestStatus) {
    HYHttpRequestSuccess = 0, // 0为成功
};

@class HYFormatData;
@interface HYHttpMgr : AFHTTPSessionManager

+ (instancetype)manager;

/**
 *  POST请求
 *
 *  @param url     请求路径
 *  @param params  请求参数
 *  @param success 请求成功后的回调
 *  @param failure 请求失败后的回调
 */
- (void)postWithURL:(NSString *)url
             params:(NSDictionary *)params
            success:(void (^)(id response))success
            failure:(void (^)(NSError *error))failure;

/**
 *  POST(上传资源)请求, 遵守SMIFormatData
 *
 *  @param url     请求路径
 *  @param params  请求参数
 *  @param formatDataArray  数组 装载SMIFormatData
 *  @param success 请求成功后的回调
 *  @param failure 请求失败后的回调
 */
- (void)postFileWithURL:(NSString *)url
                 params:(NSDictionary *)params
        formatDataArray:(NSArray<HYFormatData *> *)formatDataArray
                success:(void (^)(id response))success
               progress:(void (^)(CGFloat progress))progress
                failure:(void (^)(NSError *error))failure;

/**
 *  下载文件
 *
 *  @param request     下载请求
 *  @param progress    下载进度
 *  @param destination 存储路径
 *  @param completion  完成后的回调
 */
- (void)downloadTaskWithRequest:(NSURLRequest *)request
                       progress:(void (^)(CGFloat progress))progress
                    destination:(NSURL * (^)(NSURLResponse *response))destination
                     completion:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completion;

+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (id)mutableCopy UNAVAILABLE_ATTRIBUTE;
- (id)copy UNAVAILABLE_ATTRIBUTE;

@end

static NSString *const PName = @"imageFile";
static NSString *const VName = @"videoFile";

static NSString *const MP4MimeType = @"video/mp4";
static NSString *const pngMimeType = @"image/png";
static NSString *const jpegMimeType = @"image/jpeg";

@interface HYFormatData : NSObject

/// 文件数据
@property (nonatomic, strong) NSData *data;
/// 参数名
@property (nonatomic, copy) NSString *name;
/// 文件名
@property (nonatomic, copy) NSString *filename;
/// 文件类型
@property (nonatomic, copy) NSString *mimeType;

@end

NS_ASSUME_NONNULL_END
