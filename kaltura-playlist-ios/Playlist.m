//
//  Playlist.m
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 4/5/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import "Playlist.h"

@implementation Playlist
    

+(Playlist *) thePlaylist{
    static Playlist *thePlaylist = nil;
    if (!thePlaylist){
        thePlaylist= [[super allocWithZone:nil] init];
    }
    return thePlaylist;
}

+(id) allocWithZone:(struct _NSZone *)zone{
    return [self thePlaylist];
}

-(id) init{
    self = [super init];
    if (self){
        // set ivar
        
    }
    return self;
}


-(void)getDuration{
    for (id entrie in _entries) {
        // do something with object
        NSLog(@"%@",entrie);
        _duration += [[entrie objectForKey:@"duration"] floatValue];
        
    }
    NSLog(@"PLAYLIST DURATION: %f",_duration);
}

@end
