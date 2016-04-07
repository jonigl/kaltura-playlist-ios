//
//  Current.h
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 4/4/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Current : NSObject

@property int index;
@property double offset;

+(Current *) theCurrent;

@end
