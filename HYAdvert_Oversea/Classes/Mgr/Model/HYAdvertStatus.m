//
//  HYAdvertStatus.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/14.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "HYAdvertStatus.h"

@implementation HYAdvertStatus

+ (instancetype)statusWithPid:(NSString *)pid {
    HYAdvertStatus *status = [[HYAdvertStatus alloc] init];
    status.pid = pid;
    status.showCount = 1;
    status.showCountDaily = 1;
    status.showTime = [[NSDate date] timeIntervalSince1970];
    return status;
}

+ (instancetype)statusWithAdId:(NSString *)adId {
    HYAdvertStatus *status = [[HYAdvertStatus alloc] init];
    status.adId = adId;
    status.showCount = 1;
    status.showCountDaily = 1;
    status.showTime = [[NSDate date] timeIntervalSince1970];
    return status;
}

- (void)updateStatus {
    self.showCount++;
    self.showCountDaily++;
    self.showTime = [[NSDate date] timeIntervalSince1970];
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) ad = [self.class new];
    ad.pid = self.pid;
    ad.adId = self.adId;
    ad.showCount = self.showCount;
    ad.showCountDaily = self.showCountDaily;
    ad.closedDic = self.closedDic;
    ad.clickCount = self.clickCount;
    ad.closeCount = self.closeCount;
    ad.showTime = self.showTime;
    ad.clickTime = self.clickTime;
    ad.closeTime = self.closeTime;
    return ad;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.pid            = [aDecoder decodeObjectForKey:@"pid"];
        self.adId           = [aDecoder decodeObjectForKey:@"adId"];
        self.showCount      = [aDecoder decodeIntegerForKey:@"showCount"];
        self.showCountDaily = [aDecoder decodeIntegerForKey:@"showCountDaily"];
        self.closedDic      = [aDecoder decodeObjectForKey:@"closedDic"];
        self.clickCount     = [aDecoder decodeIntegerForKey:@"clickCount"];
        self.closeCount     = [aDecoder decodeIntegerForKey:@"closeCount"];
        self.showTime       = [aDecoder decodeDoubleForKey:@"showTime"];
        self.clickTime       = [aDecoder decodeDoubleForKey:@"clickTime"];
        self.closeTime       = [aDecoder decodeDoubleForKey:@"closeTime"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.pid forKey:@"pid"];
    [aCoder encodeObject:self.adId forKey:@"adId"];
    [aCoder encodeInteger:self.showCount forKey:@"showCount"];
    [aCoder encodeInteger:self.showCountDaily forKey:@"showCountDaily"];
    [aCoder encodeObject:self.closedDic forKey:@"closedDic"];
    [aCoder encodeInteger:self.clickCount forKey:@"clickCount"];
    [aCoder encodeInteger:self.closeCount forKey:@"closeCount"];
    [aCoder encodeDouble:self.showTime forKey:@"showTime"];
    [aCoder encodeDouble:self.clickTime forKey:@"clickTime"];
    [aCoder encodeDouble:self.closeTime forKey:@"closeTime"];
}

@end
