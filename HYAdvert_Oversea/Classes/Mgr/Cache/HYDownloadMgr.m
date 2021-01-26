//
//  HYDownloadMgr.m
//  AFNetworking
//
//  Created by Yvan on 2018/11/5.
//

#import "HYDownloadMgr.h"
#import <AFNetworking/AFNetworking.h>
#import <CommonCrypto/CommonDigest.h>

@interface HYDownloadMgr ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionMgr;
@property (nonatomic, strong) NSMutableSet *historySets;
@property (nonatomic, strong) NSMutableSet *usingSet;

@end

@implementation HYDownloadMgr {
    dispatch_semaphore_t _lock;
}

+ (instancetype)manager {
    static HYDownloadMgr *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HYDownloadMgr alloc] init];
        manager.sessionMgr = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        manager.sessionMgr.requestSerializer.timeoutInterval = 30;
        manager.sessionMgr.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain" ,@"application/json", @"text/json", @"text/javascript",@"text/html",@"image/gif", nil];
        manager.sessionMgr.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager.sessionMgr.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        manager.sessionMgr.securityPolicy.allowInvalidCertificates = YES;
        manager.sessionMgr.securityPolicy.validatesDomainName = NO;
        
        NSString *path = [[manager resultPath] stringByAppendingPathComponent:@"VideoMetaData"];
        manager.historySets =  [[NSKeyedUnarchiver unarchiveObjectWithFile:path] mutableCopy];
        manager.usingSet = [NSMutableSet set];
        manager->_lock = dispatch_semaphore_create(1);
    });
    return manager;
}

#pragma mark - FileManager

- (NSString *)fileExsitsWithKey:(NSString *)URLStr {
    NSString *key = [self md5Str:URLStr];
    NSString *resultPath = [[self resultPath] stringByAppendingPathComponent:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
        return resultPath;
    }
    return nil;
}

- (void)cacheVideosMetaDataWithURLStrs:(NSArray<NSString *> *)URLStrs {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
        
        /// 更新
        [self.usingSet addObjectsFromArray:URLStrs];
        NSString *path = [[self resultPath] stringByAppendingPathComponent:@"VideoMetaData"];
        [NSKeyedArchiver archiveRootObject:self.usingSet.copy toFile:path];
        
        for (NSString *url in URLStrs) {
            [self.historySets removeObject:url];
        }
        
        /// 移除
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (NSString *removeURLStr in self.historySets.copy) {
            NSString *key = [self md5Str:removeURLStr];
            NSString *resultPath = [[self resultPath] stringByAppendingPathComponent:key];
            NSString *tempPath = [[self tempPath] stringByAppendingPathComponent:key];
            if ([fileManager fileExistsAtPath:resultPath]) {
                 [fileManager removeItemAtPath:resultPath error:nil];
            }
            if ([fileManager fileExistsAtPath:tempPath]) {
                [fileManager removeItemAtPath:tempPath error:nil];
            }
        }
        dispatch_semaphore_signal(self->_lock);
    });
}

#pragma mark - Download

- (void)downloadWithURLStrs:(NSArray<NSString *> *)URLStrs {
    for (NSString *str in URLStrs) {
        [self downloadWithURLStr:str completion:nil];
    }
}

- (NSURLSessionDownloadTask *)downloadWithURLStr:(NSString *)URLStr
                                      completion:(void (^)(void))completion {
    // 去除中文编码
    NSString *str = [URLStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *key = [self md5Str:str];
    NSString *tempPath = [[self tempPath] stringByAppendingPathComponent:key];
    NSString *resultPath = [[self resultPath] stringByAppendingPathComponent:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
        if (completion) completion();
        return nil;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:tempPath];
    NSURLSessionDownloadTask *task = nil;
    
    if (!data) {
        task = [self newDownloadWithURLStr:URLStr tempPath:tempPath resultPath:resultPath completion:completion];
    } else {
        task = [self resumeDownloadWithURLStr:URLStr data:data tempPath:tempPath resultPath:resultPath completion:completion];
    }
    
    [task resume];

    return task;
}

- (NSURLSessionDownloadTask *)newDownloadWithURLStr:(NSString *)URLStr
                                           tempPath:(NSString *)tempPath
                                         resultPath:(NSString *)resultPath
                                         completion:(nonnull void (^)(void))completion{
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URLStr]];
    return [self.sessionMgr downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
//        NSLog(@"downloadTaskWithRequest - %F",(1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount));
    }  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:resultPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (error) {
            if (error.code == 2) { // No such file or directory
                if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
                }
                /// 待优化
                [self downloadWithURLStr:URLStr completion:completion];
                return;
            }
            
            NSData *data = [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
            if (data) {
                [data writeToFile:tempPath atomically:YES];
            }
        } else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            }
        }
        
        if (completion) completion();
    }] ;
}

- (NSURLSessionDownloadTask *)resumeDownloadWithURLStr:(NSString *)URLStr
                                                  data:(NSData *)data
                                            tempPath:(NSString *)tempPath
                                          resultPath:(NSString *)resultPath
                                            completion:(nonnull void (^)(void))completion {
    return [self.sessionMgr downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
//        NSLog(@"downloadTaskWithResumeData - %F",(1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount));
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:resultPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (error) {
            if (error.code == 2) { // No such file or directory
                if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
                }
                
                /// 待优化, 因为返回NSURLSessionDownloadTask 已经变更, 外部控制不了task
                [self downloadWithURLStr:URLStr completion:completion];
                return;
            }
            
            NSData *data = [error.userInfo objectForKey:@"NSURLSessionDownloadTaskResumeData"];
            if (data) {
                [data writeToFile:tempPath atomically:YES];
            }
        } else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
            }
        }
        
        if (completion) completion();
    }];
}

#pragma mark - Path

- (NSString *)tempPath {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"HYDownloader/temp"];
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSString *)resultPath {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"HYDownloader/result"];
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

#pragma mark - MD5

- (NSString *)md5Str:(NSString *)originalStr {
    const char *str = originalStr.UTF8String;
    int length = (int)strlen(str);
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, length, bytes);
    return [self stringFromBytes:bytes length:CC_MD5_DIGEST_LENGTH];
}

- (NSString *)stringFromBytes:(unsigned char *)bytes length:(int)length {
    NSMutableString *strM = [NSMutableString string];
    for (int i = 0; i < length; i++) {
        [strM appendFormat:@"%02x", bytes[i]];
    }
    return [strM copy];
}

@end
