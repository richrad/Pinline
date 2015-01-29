//
//  JSONResponseSerializer.m
//  Pinline
//
//  Created by Richard Allen on 1/29/15.
//  Copyright (c) 2015 TinyShop. All rights reserved.
//

#import "JSONResponseSerializer.h"

@implementation JSONResponseSerializer

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", nil];
    
    return self;
}

@end
