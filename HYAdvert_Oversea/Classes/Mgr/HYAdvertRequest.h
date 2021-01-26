//
//  HYAdvertRequest.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/13.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYAdvertRequest : NSObject

/**
 获取所有的广告数据

 @param local 历史缓存
 @param netWork 服务器数据
 @param failure 失败
 */
+ (void)getAdvertsWithLocal:(void (^)(NSDictionary *results, NSDictionary *advertStatus))local
                    netWork:(void (^)(NSDictionary *results, NSDictionary *advertStatus))netWork
                    failure:(void (^)(NSString *error))failure;

/**
 实时获取

 @param pid 广告位置
 @param completion 完成
 */
+ (void)getByRealTimeAdvertWithPid:(NSString *)pid completion:(void (^)(NSDictionary *adverts, NSDictionary *advertStatus, NSDictionary *results, NSError *error))completion;

@end
