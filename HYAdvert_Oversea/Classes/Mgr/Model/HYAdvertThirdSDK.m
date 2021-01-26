//
//  HYAdvertThirdSDK.m
//  AFNetworking
//
//  Created by Yvan on 2018/11/27.
//

#import "HYAdvertThirdSDK.h"

@implementation HYAdvertThirdSDK

+ (instancetype)thirdSDKWithDict:(NSDictionary *)dict pid:(NSString *)pid {
    if (!dict) return nil;
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    HYAdvertThirdSDK *advert = [[HYAdvertThirdSDK alloc] init];
    advert->_isOpen = [dict[@"isOpen"] boolValue];
    advert->_loadCount = [dict[@"loadCount"] integerValue];
    advert->_itemPosition = [dict[@"itemPosition"] integerValue];
    advert->_adSource = [NSString stringWithFormat:@"%ld", (long)[dict[@"adSource"] integerValue]];
    advert->_interval = [dict[@"interval"] integerValue];
    advert->_pid = pid;
    advert->_templateId = [dict[@"templateId"] integerValue];
    return advert;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self->_isOpen             = [aDecoder decodeBoolForKey:@"isOpen"];
        self->_loadCount          = [aDecoder decodeIntegerForKey:@"loadCount"];
        self->_itemPosition       = [aDecoder decodeIntegerForKey:@"itemPosition"];
        self->_adSource           = [aDecoder decodeObjectForKey:@"adSource"];
        self->_interval           = [aDecoder decodeIntegerForKey:@"interval"];
        self->_pid                = [aDecoder decodeObjectForKey:@"pid"];
        self->_templateId         = [aDecoder decodeIntegerForKey:@"templateId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.isOpen forKey:@"isOpen"];
    [aCoder encodeInteger:self.loadCount forKey:@"loadCount"];
    [aCoder encodeInteger:self.itemPosition forKey:@"itemPosition"];
    [aCoder encodeObject:self.adSource forKey:@"adSource"];
    [aCoder encodeInteger:self.interval forKey:@"interval"];
    [aCoder encodeObject:self.pid forKey:@"pid"];
    [aCoder encodeInteger:self.templateId forKey:@"templateId"];
}

@end
