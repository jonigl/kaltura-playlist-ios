//
//  Current.m
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 4/4/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import "Current.h"

@implementation Current{
    
}

@synthesize index;
@synthesize offset;

+(Current *) theCurrent{
    static Current *theCurrent = nil;
    if (!theCurrent){
        theCurrent= [[super allocWithZone:nil] init];
    }
    return theCurrent;
}

+(id) allocWithZone:(struct _NSZone *)zone{
    return [self theCurrent];
}

-(id) init{
    self = [super init];
    if (self){
        // set ivar
    }
    return self;
}

@end
