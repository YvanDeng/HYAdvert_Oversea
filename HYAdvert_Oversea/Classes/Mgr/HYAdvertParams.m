//
//  HYAdvertParams.m
//  AFNetworking
//
//  Created by Yvan on 2018/11/28.
//

#import "HYAdvertParams.h"
#import "HYAdvertConfig.h"
#import "HYHttpMgr.h"
#import <sys/utsname.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "NSObject+HYUtil.h"

/// 0-1000的随机number
static NSNumber * random1000() {
    return [NSNumber randomNumberFrom:0 to:1000];
}

/// 随机number
static NSNumber * randomAny() {
    return  [NSNumber randomNumber];
}

/// 上报的id -- 注意唯一性, userKey(UUID) + 时间戳
static NSString * reportId() {
    NSTimeInterval interval = [NSDate hy_currentTime];
    NSString *key = [NSString stringWithFormat:@"%@%f", [HYAdvertConfig userKey], interval];
    return [key hy_md5String];
}

@implementation HYAdvertParams
    
+ (NSDictionary *)reportParamsWithAdId:(NSString *)adId
                              adSource:(NSString *)adSource
                                   pid:(NSString *)pid
                             extraData:(NSString *)extraData
                             errorCode:(NSString * _Nullable)code
                              errorMsg:(NSString *)msg
                                    type:(HYAdvertReportType)type {
    
    NSMutableDictionary *parmas = [NSMutableDictionary dictionary];
    parmas[@"a"] = randomAny();
    parmas[@"b"] = adId;
    parmas[@"c"] = adSource;
    parmas[@"d"] = random1000();
    parmas[@"e"] = random1000();
    parmas[@"f"] = reportId();
    parmas[@"g"] = @(type);
    parmas[@"h"] = @([NSDate hy_currentTime]);
    parmas[@"i"] = extraData;
    parmas[@"j"] = pid;
    parmas[@"k"] = code;
    parmas[@"l"] = msg;
    return [parmas copy];
}

+ (NSDictionary *)baseParams {
    NSMutableDictionary *aParmas = [NSMutableDictionary dictionary];
    aParmas[@"a"] = [HYAdvertConfig u];
    aParmas[@"b"] = [HYAdvertConfig s];
    aParmas[@"c"] = [HYAdvertConfig qid];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"a"] = [aParmas copy];
    params[@"b"] = [HYAdvertConfig userKey];
    params[@"c"] = [HYAdvertConfig channel];
    params[@"d"] = [HYAdvertConfig platform];
    params[@"e"] = [HYAdvertConfig appType];
    params[@"f"] = [HYAdvertConfig version];
    params[@"g"] = [HYAdvertConfig sdkVersion];
    params[@"h"] = [HYAdvertConfig mcc];
    params[@"i"] = [HYAdvertConfig supportAdSource];

    return [params copy];
}

+ (NSDictionary *)realTimeParamsWithPid:(NSString *)pid {
    NSMutableDictionary *jParams = [NSMutableDictionary dictionary];
    
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    if (manager.isReachableViaWiFi) {
        jParams[@"a"] = @(2);
    } else if (manager.isReachableViaWWAN) {
        jParams[@"a"] = @(32);
    } else {
        jParams[@"a"] = @(1);
    }
    
    jParams[@"b"] = [self operatorType];
    jParams[@"c"] = [self currentDeviceModel];
    jParams[@"d"] = [[[UIDevice currentDevice] systemVersion] copy];
    
    NSMutableDictionary *params = [[self baseParams] mutableCopy];
    params[@"h"] = pid;
    params[@"i"] = [HYAdvertConfig mcc];
    params[@"j"] = [jParams copy];
    params[@"k"] = [HYAdvertConfig supportAdSource];
    params[@"ageMode"] = @([HYAdvertConfig readingMode]);
    return params.copy;
}

+ (NSString *)operatorType {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = networkInfo.subscriberCellularProvider;
    
    NSString *result = @"1";
    NSString *code = [carrier mobileNetworkCode];
    
    if ([code isEqualToString:@"00"]
        || [code isEqualToString:@"02"]
        || [code isEqualToString:@"07"]) { // 移动
        result = @"2";
    } else if ([code isEqualToString:@"03"]
              || [code isEqualToString:@"05"]) { // 电信
        result =  @"8";
    } else if ([code isEqualToString:@"01"]
               || [code isEqualToString:@"06"]) { // 联通
        result =  @"4";
    }
    return result;
}

// 获取设备的型号
+ (NSString *)currentDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    
    if ([deviceModel isEqualToString:@"iPhone3,1"])    return @"iPhone4";
    if ([deviceModel isEqualToString:@"iPhone3,2"])    return @"iPhone4";
    if ([deviceModel isEqualToString:@"iPhone3,3"])    return @"iPhone4";
    if ([deviceModel isEqualToString:@"iPhone4,1"])    return @"iPhone4S";
    if ([deviceModel isEqualToString:@"iPhone5,1"])    return @"iPhone5";
    if ([deviceModel isEqualToString:@"iPhone5,2"])    return @"iPhone5(GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPhone5,3"])    return @"iPhone5c(GSM)";
    if ([deviceModel isEqualToString:@"iPhone5,4"])    return @"iPhone5c(GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPhone6,1"])    return @"iPhone5s(GSM)";
    if ([deviceModel isEqualToString:@"iPhone6,2"])    return @"iPhone5s(GSM+CDMA)";
    if ([deviceModel isEqualToString:@"iPhone7,1"])    return @"iPhone6Plus";
    if ([deviceModel isEqualToString:@"iPhone7,2"])    return @"iPhone6";
    if ([deviceModel isEqualToString:@"iPhone8,1"])    return @"iPhone6s";
    if ([deviceModel isEqualToString:@"iPhone8,2"])    return @"iPhone6sPlus";
    if ([deviceModel isEqualToString:@"iPhone8,4"])    return @"iPhoneSE";
    // 日行两款手机型号均为日本独占，可能使用索尼FeliCa支付方案而不是苹果支付
    if ([deviceModel isEqualToString:@"iPhone9,1"])    return @"iPhone7";
    if ([deviceModel isEqualToString:@"iPhone9,2"])    return @"iPhone7Plus";
    if ([deviceModel isEqualToString:@"iPhone9,3"])    return @"iPhone7";
    if ([deviceModel isEqualToString:@"iPhone9,4"])    return @"iPhone7Plus";
    if ([deviceModel isEqualToString:@"iPhone10,1"])   return @"iPhone_8";
    if ([deviceModel isEqualToString:@"iPhone10,4"])   return @"iPhone_8";
    if ([deviceModel isEqualToString:@"iPhone10,2"])   return @"iPhone_8_Plus";
    if ([deviceModel isEqualToString:@"iPhone10,5"])   return @"iPhone_8_Plus";
    if ([deviceModel isEqualToString:@"iPhone10,3"])   return @"iPhoneX";
    if ([deviceModel isEqualToString:@"iPhone10,6"])   return @"iPhoneX";
    if ([deviceModel isEqualToString:@"iPhone11,8"])   return @"iPhoneXR";
    if ([deviceModel isEqualToString:@"iPhone11,2"])   return @"iPhoneXS";
    if ([deviceModel isEqualToString:@"iPhone11,6"])   return @"iPhoneXSMax";
    if ([deviceModel isEqualToString:@"iPhone11,4"])   return @"iPhoneXSMax";
    
    if ([deviceModel isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceModel isEqualToString:@"x86_64"])       return @"Simulator";
    
    return deviceModel;
}

@end
