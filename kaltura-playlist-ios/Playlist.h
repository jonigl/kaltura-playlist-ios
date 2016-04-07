//
//  Playlist.h
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 4/5/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Current.h"

@interface Playlist : NSObject {
    double playlist_module;
}

@property (nonatomic,strong) NSArray *entries;
@property double duration;
@property double timestamp;

+(Playlist *) thePlaylist;

-(void)getDuration;

-(void)findCurrent;

-(void)nextEntrie;

-(NSString *)getCurrentEntrieID;

-(double)getCurrentOffset;

-(BOOL)isLastEntrie;

-(BOOL)isFirstEntrie;

/*
-(void)setCurrent:(Current *)current;
*/
@end
