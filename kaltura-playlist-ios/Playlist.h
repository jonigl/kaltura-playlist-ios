//
//  Playlist.h
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 4/5/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Current.h"

@interface Playlist : NSObject

@property (nonatomic,strong) NSArray *entries;
@property float duration;


+(Playlist *) thePlaylist;

-(void)getDuration;
/*
-(void)findCurrent;
-(Current *)getCurrent;
-(void)setCurrent:(Current *)current;
*/
@end
