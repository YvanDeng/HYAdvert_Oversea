//
//  HYAdvertThirdSDK.h
//  AFNetworking
//
//  Created by Yvan on 2018/11/27.
//

#import <Foundation/Foundation.h>

/// 第三方SDK配置
@interface HYAdvertThirdSDK : NSObject<NSCoding>

/// SDK开关
@property (nonatomic, assign, readonly) BOOL isOpen;
/// 加载数量
@property (nonatomic, assign, readonly) NSInteger loadCount;
/// 广点通位置
@property (nonatomic, assign, readonly) NSInteger itemPosition;
/// 广告渠道
@property (nonatomic, copy, readonly) NSString *adSource;
/// 时间间隔
@property (nonatomic, assign, readonly) NSInteger interval;
/// 广告位
@property (nonatomic, copy, readonly) NSString *pid;
/// 广告UI样式
@property (nonatomic, assign, readonly) NSInteger templateId;

+ (instancetype)thirdSDKWithDict:(NSDictionary *)dict pid:(NSString *)pid;

@end
