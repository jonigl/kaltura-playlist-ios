//
//  Playlist.m
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 4/5/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import "Playlist.h"
#import "Current.h"
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

-(void)findCurrent{
    double acumulator = 0;
    double video_offset = 0;
    int video_index = 0;
    // needed for module calculation
    [self getDuration];
    // Se calcula el resto entre la duraci'on de la playlist y los segundos pasados desde el comienzo del día a la hora actual
    playlist_module =  fmod(_timestamp,_duration);
    
    if (playlist_module != 0) {
        
        for (int i=0; i< [_entries count]; i++) {
            
            acumulator += [[_entries[i] objectForKey:@"duration"] floatValue];
            
            if (acumulator > playlist_module) {
                video_index = i;
                NSLog(@"bigger");
                break;
            }
            
            if (acumulator == playlist_module) {
                video_index = i + 1;
                NSLog(@"equal");
                break;
            }
        }
    }
    else {
        video_index = 0;
        NSLog(@"modulo is zero, playlist starts from the beginning");
    }
    
    NSLog(@"Current video to play is %d",video_index);
    
    // Se calcula el offset sobre el video que se debe reproducir
    video_offset = playlist_module + [[_entries[video_index] objectForKey:@"duration"] floatValue] - acumulator;
    video_offset = round(video_offset);
    
    NSLog(@"Video offset is %f",video_offset);
    
    [[Current theCurrent] setIndex:video_index];
    [[Current theCurrent] setOffset:video_offset];
    
}

-(void)nextEntrie{
    int video_index;
    video_index = [[Current theCurrent] index];
    video_index++;
    [[Current theCurrent] setIndex:video_index];
    [[Current theCurrent] setOffset:0];
}


-(NSString *)getCurrentEntrieID{
    int video_index;
    NSString *entryID;
    video_index = [[Current theCurrent] index];
    entryID = [_entries[video_index] objectForKey:@"id"];
    return entryID;
    
}

-(double)getCurrentOffset{
    double video_offset;
    video_offset = [[Current theCurrent] offset];
    return video_offset;
}

-(BOOL)isLastEntrie{
    return [_entries count] - 1 == [[Current theCurrent] index];
}

-(BOOL)isFirstEntrie{
    return [[Current theCurrent] index] == 0;
}

-(BOOL)isSetEntries{
    return [_entries count] > 0;
}

@end
