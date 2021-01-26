//
//  HYAdvertStatus.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/14.
//  Copyright © 2018年 Yvan. All rights reserved.
//

/// 客户端存储的对应广告的状态

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 当前用于记录广告位的展示次数(总的、每日)等
@interface HYAdvertStatus : NSObject <NSCoding, NSCopying>

/**< 广告位Id */
@property (nonatomic, copy) NSString *pid;

/**< 广告Id */
@property (nonatomic, copy, nullable) NSString *adId;

/**< 总的已经展示次数 */
@property (nonatomic, assign) NSUInteger showCount;

/**< 每日的已经展示的次数 */
@property (nonatomic, assign) NSUInteger showCountDaily;

/**< 展示时间 */
@property (nonatomic, assign) NSTimeInterval showTime;

/**< 广告位关闭字典  key：日期(年月日) value：是否关闭 */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *closedDic;

/// 初始化状态
+ (instancetype)statusWithPid:(NSString *)pid;
+ (instancetype)statusWithAdId:(NSString *)adId;
/// 更新状态
- (void)updateStatus;


/// 预留字段
/**< 点击的次数 */
@property (nonatomic, assign) NSUInteger clickCount;

/**< 关闭的次数 */
@property (nonatomic, assign) NSUInteger closeCount;

/**< 点击时间 */
@property (nonatomic, assign) NSTimeInterval clickTime;

/**< 关闭时间 */
@property (nonatomic, assign) NSTimeInterval closeTime;

@end

NS_ASSUME_NONNULL_END
