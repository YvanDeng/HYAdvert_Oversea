//
//  HYHttpMgr.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "HYHttpMgr.h"
#import "NSObject+HYUtil.h"
#import "HYAdvertConfig.h"

static void HTTPHeaderSign(NSString *parmasStr) {
    if (!parmasStr) parmasStr = @"";
    NSString *signStr = [parmasStr stringByAppendingString:signKey];
    NSString *sign = [signStr hy_md5String];
    [[HYHttpMgr manager].requestSerializer setValue:sign forHTTPHeaderField:@"SIGN"];
    HYAdvertLog(@"SIGN = %@", sign);
}

@implementation HYHttpMgr

+ (instancetype)manager {
    static HYHttpMgr *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *urlStr = [HYAdvertConfig usingURLStr];
        
        manager = [[self alloc] initWithBaseURL:[NSURL URLWithString:urlStr] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        manager.requestSerializer.timeoutInterval = 10;

        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        manager.securityPolicy.allowInvalidCertificates = YES;
        manager.securityPolicy.validatesDomainName = NO;
        
        AFJSONResponseSerializer *responseSerializer =  [AFJSONResponseSerializer serializer];
        responseSerializer.removesKeysWithNullValues = YES;
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain" ,@"application/json", @"text/json", @"text/javascript",@"text/html",@"image/gif", nil];
        manager.responseSerializer = responseSerializer;
    });
    
    return manager;
}

- (void)postWithURL:(NSString *)url params:(NSDictionary *)params success:(void (^)(id))success failure:(void (^)(NSError *))failure {
    HYAdvertLog(@"url = %@%@, params = %@", [HYAdvertConfig usingURLStr],url, params);
    NSString *parmasStr = [params hy_jsonString];
    HTTPHeaderSign(parmasStr);
    NSDictionary *newParams = [parmasStr hy_jsonValue];
    [self POST:url parameters:newParams headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        HYAdvertLog(@"responseObject = %@", responseObject);
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == HYHttpRequestSuccess) {
            if (success) success(responseObject);
        } else {
            if (failure) {
                NSString *message = responseObject[@"message"];
                failure([NSError errorWithDomain:message code:code userInfo:nil]);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        HYAdvertLog(@"%@", error);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)postFileWithURL:(NSString *)url params:(NSDictionary *)params formatDataArray:(NSArray<HYFormatData *> *)formatDataArray success:(void (^)(id))success progress:(void (^)(CGFloat))progress failure:(void (^)(NSError *))failure {
    [self POST:url parameters:params headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull totalFormData) {
        for (HYFormatData *formData in formatDataArray) {
            [totalFormData appendPartWithFileData:formData.data name:formData.name fileName:formData.filename mimeType:formData.mimeType];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.fractionCompleted);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == HYHttpRequestSuccess) {
            if (success) {
                success(responseObject);
            }
        } else {
            
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

    }];
}

- (void)downloadTaskWithRequest:(NSURLRequest *)request progress:(void (^)(CGFloat))progress destination:(NSURL *(^)(NSURLResponse *))destination completion:(void (^)(NSURLResponse *, NSURL *, NSError *))completion {
    [[self downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress(downloadProgress.fractionCompleted);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return destination(response);
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        /// 后期再判断状态
        if (completion) {
            completion(response, filePath, error);
        }
    }] resume];
}
@end

@implementation HYFormatData
@end
