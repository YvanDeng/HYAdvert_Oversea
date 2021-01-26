//
//  HYAdvertConstant.h
//  Pods
//
//  Created by 邓逸远 on 2020/10/27.
//

#ifndef HYAdvertConstant_h
#define HYAdvertConstant_h

typedef NS_ENUM(NSInteger, HYAdvertErrorCode) {
    HYAdvertErrorForbidden = 109901,               // 广告位被禁止
    HYAdvertErrorBusinessTimeout = 109902,         // 业务总体超时
    HYAdvertErrorResponseFormatInvalid = 109903,   // 响应格式无效
    HYAdvertErrorForbiddenToday = 109904,          // 广告位当天被禁止
    HYAdvertErrorResourceDownloadFailed = 109905,  // 广告位资源下载失败
};

#endif /* HYAdvertConstant_h */
