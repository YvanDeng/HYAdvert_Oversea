//
//  HYAdvertControl.m
//  AFNetworking
//
//  Created by Yvan on 2018/11/27.
//

#import "HYAdvertControl.h"

@implementation HYAdvertControl

+ (instancetype)advertControlWithDict:(NSDictionary *)dict pid:(NSString *)pid {
    if (!dict) return nil;
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    HYAdvertControl *congif = [[HYAdvertControl alloc] init];
    congif->_hotSplash = [dict[@"hotSplash"] boolValue];
    congif->_pid = pid;
    return congif;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self->_hotSplash = [aDecoder decodeBoolForKey:@"hotSplash"];
        self->_pid = [aDecoder decodeObjectForKey:@"pid"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.hotSplash forKey:@"hotSplash"];
    [aCoder encodeObject:self.pid forKey:@"pid"];
}

@end
