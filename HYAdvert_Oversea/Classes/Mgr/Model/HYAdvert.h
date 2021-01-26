//
//  HYAdvertisement.h
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/7.
//  Copyright © 2018年 Yvan. All rights reserved.
//

/// 服务器下发的字段, get/getRealTime

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 点击后的打开模式
typedef NS_ENUM(NSUInteger, HYAdvertClickType) {
    HYAdvertClickNone        = 0,        // 0-无动作
    HYAdvertClickInnerPage   = 1,        // 1-进入应用内页面
    HYAdvertClickOuterURL    = 2,        // 2-应用外打开URL
};

/// 广告资源类型，SDK内部使用
typedef NS_ENUM(NSUInteger, HYAdvertSourceType) {
    HYAdvertSourceNormal,   // 普通广告，启动时一次性获取
    HYAdvertSourceRealTime, // 实时广告，单条获取
};

/// 广告数据类型
typedef NS_ENUM(NSUInteger, HYAdvertDataType) {
    HYAdvertDataPic,        // 图片
    HYAdvertDataGif,        // 动图
    HYAdvertDataVideo,      // 视频
    HYAdvertDataPicLoop,    // 多图
    HYAdvertDataTextLoop,   // 纯文本
};

@interface HYAdvertContent : NSObject<NSCoding, NSCopying>
    
/**< 广告内容图片链接 */
@property (nonatomic, copy, nullable, readonly) NSString *adUrl;

/**< 广告标题 */
@property (nonatomic, copy, nullable, readonly) NSString *adTitle;
    
/**< 广告子标题 */
@property (nonatomic, copy, nullable, readonly) NSString *adSubtitle;

/**< 广告内容 */
@property (nonatomic, copy, nullable, readonly) NSString *adText;

/**< 跳转链接 */
@property (nonatomic, copy, nullable, readonly) NSString *clickLink;

/**< 广告条目的位置
 表示插入的位置 或 广告起始章节，以1为起点，服务器和客户端都做保护>=0
 */
@property (nonatomic, assign, readonly) NSInteger adItemPosition;

/**
 闪屏时长
 章节间隔，取实际数字（3表示间隔3章）
 */
@property (nonatomic, assign, readonly) NSInteger interval;

/**< 广告类型：1、广告 2、推书 3、书单 4、h5 */
@property (nonatomic, assign, readonly) NSInteger adType;

/**< 书籍Id */
@property (nonatomic, copy, nullable, readonly) NSString *bookId;

/**< 书单Id 或 其它Id */
@property (nonatomic, copy, nullable, readonly) NSString *contentId;

/**< 备注，例如图片素材名 */
@property (nonatomic, copy, nullable, readonly) NSString *remark;

/**< 附加信息json字符串，需要解析，例如推书的书籍详情信息 */
@property (nonatomic, copy, nullable, readonly) NSString *extraInfo;

/// 字典转模型
+ (instancetype)advertContentWithDict:(NSDictionary *)dict;

@end

@interface HYAdvert : NSObject <NSCoding, NSCopying>

/**< 广告Id，由于某个位的广告会多次配置，因此，在存储某个广告位的配置时，不要使用这个id */
@property (nonatomic, copy, readonly) NSString *adId;

/**< 广告渠道 */
@property (nonatomic, copy, readonly) NSString *adSource;

/**< 开始时间 */
@property (nonatomic, assign, readonly) NSTimeInterval startTime;

/**< 结束时间 */
@property (nonatomic, assign, readonly) NSTimeInterval endTime;

/**< 过期时间  */
@property (nonatomic, assign, readonly) NSInteger expireTime;

/**< 广告标题， */
@property (nonatomic, copy, nullable, readonly) NSString *adTitle API_DEPRECATED("Use HYAdvertContent's adTitle instead", ios(5.0, 8.0));

/**< 广告内容 */
@property (nonatomic, copy, nullable, readonly) NSString *adText API_DEPRECATED("Use HYAdvertContent's adText instead", ios(5.0, 8.0));

/**
 adItemPosition 字段
 表示插入的位置时，以0为起点（0表示第1个），服务器和客户端都做保护>=0
 表示间隔章节时，取实际数字（3表示间隔3章）, 服务器和客户端都做保护>0
 不使用这个参数的广告位时，为-1的默认值
 */
@property (nonatomic, assign, readonly) NSInteger adItemPosition API_DEPRECATED("Use HYAdvertContent's adItemPosition instead", ios(5.0, 8.0));

/**< 广告图片链接
    gif链接
    video本地路径
 */
@property (nonatomic, copy, nullable, readonly) NSString *adUrl API_DEPRECATED("Use HYAdvertContent's adUrl instead", ios(5.0, 8.0));

/**< 本地资源文件路径 */
@property (nonatomic, copy, nullable, readonly) NSString *filePath;
    
/**< 点击后的打开模式 */
@property (nonatomic, assign, readonly) HYAdvertClickType clickType;

/**< 跳转使用, jsonString
 {
 "page": "className", // 类名
 "parmas": {          // 字典参数
    "key": "value",
 }
 }*/
@property (nonatomic, copy, nullable, readonly) NSString *clickLink API_DEPRECATED("Use HYAdvertContent's clickLink instead", ios(5.0, 8.0));

/**< 最多展示的次数 */
@property (nonatomic, assign, readonly) NSInteger showCount;

/**< 每日的最多展示次数 */
@property (nonatomic, assign, readonly) NSInteger showCountDaily;

/**< 已经展示过的总次数 */
@property (nonatomic, assign, readonly) NSUInteger hasShowedCount;

/**< 展示时长 秒 */
@property (nonatomic, assign, readonly) NSUInteger showTime;

/**< 展示类型 */
@property (nonatomic, assign, readonly) NSInteger showType;

/**< 优先级, 数值越大, 优先级越高 */
@property (nonatomic, assign, readonly) NSUInteger priority;

/**< 能否关闭, 能关闭, 需要显示关闭按钮 */
@property (nonatomic, assign, readonly) BOOL canClose;

/**< 是否显示logo - 针对于闪屏 */
@property (nonatomic, assign, readonly) BOOL adShowLogo;

/**< 广告位 */
@property (nonatomic, copy, readonly) NSString *pid;

/**< 上报回传给服务器 */
@property (nonatomic, copy, readonly) NSString *extraData;

/**< 广告UI样式  */
@property (nonatomic, assign, readonly) NSInteger templateId;

/**< 是否展示广告标签 */
@property (nonatomic, assign, readonly) BOOL adShowTag;

/**< 展示时间间隔 */
@property (nonatomic, assign, readonly) NSInteger interval API_DEPRECATED("Use HYAdvertContent's interval instead", ios(5.0, 8.0));

/**< 展示类型 0.图片 1.动态图 2.视频 3.图文跑马灯 4.文字跑马灯 */
@property (nonatomic, assign, readonly) HYAdvertDataType showMode;

/**< 关闭逻辑 1.单次启动周期内不在展示 2.当天内不再展示 3.页面刷新重新出现 */
@property (nonatomic, assign, readonly) NSInteger closeLogic;

/**< 广告触发日期 */
@property (nonatomic, assign, readonly) NSInteger adTriggerDay;
    
/**< 广告内容 */
@property (nonatomic, copy, readonly) NSArray<HYAdvertContent *> *adList;

/**< 是否删除本地缓存 */
@property (nonatomic, assign) NSInteger isDelLocal;

/// 字典转模型
+ (instancetype)advertWithDict:(NSDictionary *)dict pid:(NSString *)pid source:(HYAdvertSourceType)source;

///  内部使用
/**< 区分:get / getRealTime */
@property (nonatomic, assign, readonly) HYAdvertSourceType sourceType;

@end

NS_ASSUME_NONNULL_END
