//
//  HYAdvertisement.m
//  HYAdvertisement_Example
//
//  Created by Yvan on 2018/9/7.
//  Copyright © 2018年 Yvan. All rights reserved.
//

#import "HYAdvert.h"

@implementation HYAdvertContent
    
+ (instancetype)advertContentWithDict:(NSDictionary *)dict {
    if (!dict) return nil;
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    HYAdvertContent *advertContent = [HYAdvertContent new];
    advertContent->_adUrl = dict[@"adUrl"];
    advertContent->_adTitle = dict[@"adTitle"];
    advertContent->_adSubtitle = dict[@"adSubtitle"];
    advertContent->_adText = dict[@"adText"];
    advertContent->_clickLink = dict[@"clickLink"];
    advertContent->_adItemPosition = [dict[@"adItemPosition"] integerValue];
    advertContent->_interval = [dict[@"interval"] integerValue];
    advertContent->_adType = [dict[@"adType"] integerValue];
    advertContent->_bookId = [NSString stringWithFormat:@"%@", dict[@"bookId"]];
    advertContent->_contentId = [NSString stringWithFormat:@"%@", dict[@"contentId"]];
    advertContent->_remark = dict[@"remark"];
    advertContent->_extraInfo = dict[@"extraInfo"];
    
    return advertContent;
}
    
- (id)copyWithZone:(NSZone *)zone {
    typeof(self) advertContent = [self.class new];
    advertContent->_adUrl = self.adUrl;
    advertContent->_adTitle = self.adTitle;
    advertContent->_adSubtitle = self.adSubtitle;
    advertContent->_adText = self.adText;
    advertContent->_clickLink = self.clickLink;
    advertContent->_adItemPosition = self.adItemPosition;
    advertContent->_interval = self.interval;
    advertContent->_adType = self.adType;
    advertContent->_bookId = self.bookId;
    advertContent->_contentId = self.contentId;
    advertContent->_remark = self.remark;
    advertContent->_extraInfo = self.extraInfo;
    return advertContent;
}
    
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self->_adTitle = [aDecoder decodeObjectForKey:@"adTitle"];
        self->_adSubtitle = [aDecoder decodeObjectForKey:@"adSubtitle"];
        self->_adText = [aDecoder decodeObjectForKey:@"adText"];
        self->_adUrl = [aDecoder decodeObjectForKey:@"adUrl"];
        self->_clickLink = [aDecoder decodeObjectForKey:@"clickLink"];
        self->_adItemPosition = [aDecoder decodeIntegerForKey:@"adItemPosition"];
        self->_interval = [aDecoder decodeIntegerForKey:@"interval"];
        self->_adType = [aDecoder decodeIntegerForKey:@"adType"];
        self->_bookId = [aDecoder decodeObjectForKey:@"bookId"];
        self->_contentId = [aDecoder decodeObjectForKey:@"contentId"];
        self->_remark = [aDecoder decodeObjectForKey:@"remark"];
        self->_extraInfo = [aDecoder decodeObjectForKey:@"extraInfo"];
    }
    
    return self;
}
    
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.adTitle forKey:@"adTitle"];
    [aCoder encodeObject:self.adSubtitle forKey:@"adSubtitle"];
    [aCoder encodeObject:self.adText forKey:@"adText"];
    [aCoder encodeObject:self.adUrl forKey:@"adUrl"];
    [aCoder encodeObject:self.clickLink forKey:@"clickLink"];
    [aCoder encodeInteger:self.adItemPosition forKey:@"adItemPosition"];
    [aCoder encodeInteger:self.interval forKey:@"interval"];
    [aCoder encodeInteger:self.adType forKey:@"adType"];
    [aCoder encodeObject:self.bookId forKey:@"bookId"];
    [aCoder encodeObject:self.contentId forKey:@"contentId"];
    [aCoder encodeObject:self.remark forKey:@"remark"];
    [aCoder encodeObject:self.extraInfo forKey:@"extraInfo"];
}

@end

@implementation HYAdvert
    
+ (instancetype)advertWithDict:(NSDictionary *)dict pid:(NSString *)pid source:(HYAdvertSourceType)source {
    if (!dict) return nil;
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    HYAdvert *advert = [[HYAdvert alloc] init];
    advert->_adId = dict[@"adId"];
    advert->_adSource = [NSString stringWithFormat:@"%ld", (long)[dict[@"adSource"] integerValue]];
    advert->_startTime = [dict[@"startTime"] doubleValue];
    advert->_endTime = [dict[@"endTime"] doubleValue];
    advert->_expireTime = [dict[@"expireTime"] integerValue];
    advert->_adTitle = dict[@"adTitle"];
    advert->_adText = dict[@"adText"];
    advert->_adItemPosition = [dict[@"adItemPosition"] integerValue];
    advert->_adUrl = dict[@"adUrl"];
    advert->_clickType = [dict[@"clickType"] integerValue];
    advert->_clickLink = dict[@"clickLink"];
    advert->_adTriggerDay = [dict[@"adTiggerDay"] integerValue];
    advert->_showCount = [dict[@"showCount"] integerValue];
    advert->_showCountDaily = [dict[@"showCountDaily"] integerValue];
    advert->_hasShowedCount = [dict[@"hasShowedCount"] integerValue];
    advert->_priority = [dict[@"priority"] integerValue];
    advert->_canClose = [dict[@"canClose"] boolValue];
    advert->_adShowLogo = [dict[@"adShowLogo"] boolValue];
    advert->_extraData = dict[@"extraData"];
    advert->_sourceType = source;
    advert->_pid = pid;
    advert->_showTime = [dict[@"showTime"] integerValue];
    advert->_showType = [dict[@"showType"] integerValue];
    advert->_templateId = [dict[@"templateId"] integerValue];
    advert->_adShowTag = [dict[@"adShowTag"] boolValue];
    advert->_showMode = [dict[@"showMode"] integerValue];
    advert->_interval = [dict[@"interval"] integerValue];
    advert->_closeLogic = [dict[@"closeLogic"] integerValue];
    advert->_isDelLocal = [dict[@"isDelLocal"] integerValue];
    
    // 新的广告内容，支持配置多个图片或文本
    NSArray *adList = dict[@"adList"];
    if (![adList isKindOfClass:[NSArray class]]) {
        advert->_adList = @[];
    } else {
        NSMutableArray *mAdList = [NSMutableArray array];
        for (NSDictionary *tmpDict in adList) {
            HYAdvertContent *advertContent = [HYAdvertContent advertContentWithDict:tmpDict];
            if (advertContent) {
                [mAdList addObject:advertContent];
            }
        }
        advert->_adList = mAdList.copy;
    }
    
    // 服务下发次数为 -1 时，表示无限次展示，此处赋值最大值，达此效果
    if (advert->_showCount == -1) {
        advert->_showCount = NSIntegerMax;
    }
    if (advert->_showCountDaily == -1) {
        advert->_showCountDaily = NSIntegerMax;
    }
    
    return advert;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) advert = [self.class new];
    advert->_adId = self.adId;
    advert->_startTime = self.startTime;
    advert->_endTime = self.endTime;
    advert->_expireTime = self.expireTime;
    advert->_adTitle = self.adTitle;
    advert->_adText = self.adText;
    advert->_adItemPosition = self.adItemPosition;
    advert->_adUrl = self.adUrl;
    advert->_clickType = self.clickType;
    advert->_clickLink = self.clickLink;
    advert->_adTriggerDay = self.adTriggerDay;
    advert->_showCount = self.showCount;
    advert->_showCountDaily = self.showCountDaily;
    advert->_hasShowedCount = self.hasShowedCount;
    advert->_priority = self.priority;
    advert->_canClose = self.canClose;
    advert->_adShowLogo = self.adShowLogo;
    advert->_pid = self.pid;
    advert->_extraData = self.extraData;
    advert->_adSource = self.adSource;
    advert->_sourceType = self.sourceType;
    advert->_showTime = self.showTime;
    advert->_showType = self.showType;
    advert->_templateId = self.templateId;
    advert->_adShowTag = self.adShowTag;
    advert->_showMode = self.showMode;
    advert->_interval = self.interval;
    advert->_adList = self.adList;
    advert->_closeLogic = self.closeLogic;
    advert->_isDelLocal = self.isDelLocal;
    
    return advert;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self->_adId = [aDecoder decodeObjectForKey:@"adId"];
        self->_startTime = [aDecoder decodeDoubleForKey:@"startTime"];
        self->_endTime = [aDecoder decodeDoubleForKey:@"endTime"];
        self->_expireTime = [aDecoder decodeIntegerForKey:@"expireTime"];
        self->_adTitle = [aDecoder decodeObjectForKey:@"adTitle"];
        self->_adText = [aDecoder decodeObjectForKey:@"adText"];
        self->_adItemPosition = [aDecoder decodeIntegerForKey:@"adItemPosition"];
        self->_adUrl = [aDecoder decodeObjectForKey:@"adUrl"];
        self->_clickType = [aDecoder decodeIntegerForKey:@"clickType"];
        self->_clickLink = [aDecoder decodeObjectForKey:@"clickLink"];
        self->_showCount = [aDecoder decodeIntegerForKey:@"showCount"];
        self->_showCountDaily = [aDecoder decodeIntegerForKey:@"showCountDaily"];
        self->_hasShowedCount = [aDecoder decodeIntegerForKey:@"hasShowedCount"];
        self->_priority = [aDecoder decodeIntegerForKey:@"priority"];
        self->_canClose = [aDecoder decodeBoolForKey:@"canClose"];
        self->_adShowLogo = [aDecoder decodeBoolForKey:@"adShowLogo"];
        self->_pid = [aDecoder decodeObjectForKey:@"pid"];
        self->_extraData = [aDecoder decodeObjectForKey:@"extraData"];
        self->_adSource = [aDecoder decodeObjectForKey:@"adSource"];
        self->_sourceType = [aDecoder decodeIntegerForKey:@"sourceType"];
        self->_showTime = [aDecoder decodeIntegerForKey:@"showTime"];
        self->_showType = [aDecoder decodeIntegerForKey:@"showType"];
        self->_templateId = [aDecoder decodeIntegerForKey:@"templateId"];
        self->_adShowTag = [aDecoder decodeBoolForKey:@"adShowTag"];
        self->_showMode = [aDecoder decodeIntegerForKey:@"showMode"];
        self->_interval = [aDecoder decodeIntegerForKey:@"interval"];
        self->_adList = [aDecoder decodeObjectForKey:@"adList"];
        self->_closeLogic = [aDecoder decodeIntegerForKey:@"closeLogic"];
        self->_adTriggerDay = [aDecoder decodeIntegerForKey:@"adTriggerDay"];
        self->_isDelLocal = [[aDecoder decodeObjectForKey:@"isDelLocal"] integerValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.adId forKey:@"adId"];
    [aCoder encodeDouble:self.startTime forKey:@"startTime"];
    [aCoder encodeDouble:self.endTime forKey:@"endTime"];
    [aCoder encodeInteger:self.expireTime forKey:@"expireTime"];
    [aCoder encodeObject:self.adTitle forKey:@"adTitle"];
    [aCoder encodeObject:self.adText forKey:@"adText"];
    [aCoder encodeInteger:self.adItemPosition forKey:@"adItemPosition"];
    [aCoder encodeObject:self.adUrl forKey:@"adUrl"];
    [aCoder encodeInteger:self.clickType forKey:@"clickType"];
    [aCoder encodeObject:self.clickLink forKey:@"clickLink"];
    [aCoder encodeInteger:self.showCount forKey:@"showCount"];
    [aCoder encodeInteger:self.showCountDaily forKey:@"showCountDaily"];
    [aCoder encodeInteger:self.hasShowedCount forKey:@"hasShowedCount"];
    [aCoder encodeInteger:self.priority forKey:@"priority"];
    [aCoder encodeBool:self.canClose forKey:@"canClose"];
    [aCoder encodeBool:self.adShowLogo forKey:@"adShowLogo"];
    [aCoder encodeObject:self.pid forKey:@"pid"];
    [aCoder encodeObject:self.extraData forKey:@"extraData"];
    [aCoder encodeObject:self.adSource forKey:@"adSource"];
    [aCoder encodeInteger:self.sourceType forKey:@"sourceType"];
    [aCoder encodeInteger:self.showTime forKey:@"showTime"];
    [aCoder encodeInteger:self.showType forKey:@"showType"];
    [aCoder encodeInteger:self.templateId forKey:@"templateId"];
    [aCoder encodeBool:self.adShowTag forKey:@"adShowTag"];
    [aCoder encodeInteger:self.showMode forKey:@"showMode"];
    [aCoder encodeInteger:self.interval forKey:@"interval"];
    [aCoder encodeObject:self.adList forKey:@"adList"];
    [aCoder encodeInteger:self.closeLogic forKey:@"closeLogic"];
    [aCoder encodeInteger:self.adTriggerDay forKey:@"adTriggerDay"];
    [aCoder encodeObject:@(self.isDelLocal) forKey:@"isDelLocal"];
}

@end
