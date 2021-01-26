//
//  HYAdvertControl.h
//  AFNetworking
//
//  Created by Yvan on 2018/11/27.
//

#import <Foundation/Foundation.h>

/// 控制行为
@interface HYAdvertControl : NSObject<NSCoding>

/// 热启动, 后台进入前台是否需要闪屏广告
@property (nonatomic, assign, readonly) BOOL hotSplash;
@property (nonatomic, copy, readonly) NSString *pid;

+ (instancetype)advertControlWithDict:(NSDictionary *)dict pid:(NSString *)pid;

@end
