//
//  ViewController.m
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 3/21/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import "ViewController.h"
#import <KALTURAPlayerSDK/KPViewController.h>

@interface ViewController () <KPViewControllerDelegate>
@property (retain, nonatomic) KPViewController *player;
@end

@implementation ViewController {
    KPPlayerConfig *config;
}

static int counter;
static NSArray *entryIds;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player.delegate = self;
    // Get playlist from API
    [self getPlaylist];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (KPViewController *)player {
    if (!_player) {
        // Account Params
        config = [[KPPlayerConfig alloc] initWithServer:@"http://vodgc.com"
                                               uiConfID:@"23448994"
                                              partnerId:@"109"];
        // Setting this property will cache the html pages in the limit size
       // config.cacheSize = 0.8;
        [config addConfigKey:@"autoPlay" withValue:@"true"];
        [self hideHTMLControls];
        //[config setEntryId: @"0_q7mmw9yy"];
        _player = [[KPViewController alloc] initWithConfiguration:config];
        NSLog(@"PLAYER CONFIGURED");
    }
    return _player;
}

- (void)hideHTMLControls {
    // chromeless config
    // Set AutoPlay as configuration on player (same like setting a flashvar)
   // [config addConfigKey:@"controlBarContainer.plugin" withValue:@"false"];
    // whitout poster
    [config addConfigKey:@"EmbedPlayer.HidePosterOnStart" withValue:@"true"];
    [config addConfigKey:@"topBarContainer.plugin" withValue:@"false"];
    [config addConfigKey:@"largePlayBtn.plugin" withValue:@"false"];
    [config addConfigKey:@"loadingSpinner.plugin" withValue:@"false"];
}

- (void)kPlayer:(KPViewController *)player playerPlaybackStateDidChange:(KPMediaPlaybackState)state{
    [self logPlaybackState: state];
    if (state == KPMediaPlaybackStateEnded && counter < [entryIds count]-1){
        counter = counter + 1;
        NSLog(@"NEXT VIDEO");
        [player changeMedia:entryIds[counter]];
    }
    if (state == KPMediaPlaybackStatePaused && counter < [entryIds count]-1){
        //[player.playerController play];
    }
    
}


- (void)kPlayer:(KPViewController *)player playerLoadStateDidChange:(KPMediaLoadState)state{
    NSLog(@"PLAYER LOAD STATE DID CHANGE TO: %ld", (long)state);
}


-(void)logPlaybackState: (KPMediaPlaybackState)state {
    NSLog(@"PLAYER PLAYBACK STATE DID CHANGE TO:");
    switch (state) {
        case KPMediaPlaybackStateUnknown:
            NSLog(@"KPMediaPlaybackStateUnknown");
            break;
        case KPMediaPlaybackStateLoaded:
            NSLog(@"KPMediaPlaybackStateLoaded");
            break;
        case KPMediaPlaybackStateReady:
            NSLog(@"KPMediaPlaybackStateReady");
            break;
        case KPMediaPlaybackStatePlaying:
            NSLog(@"KPMediaPlaybackStatePlaying");
            break;
        case KPMediaPlaybackStatePaused:
            NSLog(@"KPMediaPlaybackStatePaused");
            break;
        case KPMediaPlaybackStateEnded:
            NSLog(@"KPMediaPlaybackStateEnded");
            break;
        case KPMediaPlaybackStateInterrupted:
            NSLog(@"KPMediaPlaybackStateInterrupted");
            break;
        case KPMediaPlaybackStateSeekingForward:
            NSLog(@"KPMediaPlaybackStateSeekingForward");
            break;
        case KPMediaPlaybackStateSeekingBackward:
            NSLog(@"KPMediaPlaybackStateSeekingBackward");
            break;
        default:
            break;
    }
}

-(void)getPlaylist {
    NSLog(@"GET REQUEST PLAYLIST");
    // 1. The web address & headers
    NSString *webAddress = @"http://precr.com.ar:8080/api/playlist/radiox/lunes";
    
    // 2. An NSURL wrapped in an NSURLRequest
    NSURL* url = [NSURL URLWithString:webAddress];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 3. An NSURLSession Configuration
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // 4. The URLSession itself.
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    // 5. A session task: NSURLSessionDataTask or NSURLSessionDownloadTask
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *parseError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        NSLog(@"%@", json);
        entryIds = [json objectForKey:@"playlist"];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            dispatch_async(dispatch_get_main_queue(), ^(void){
                //Run UI Updates
                //Background Thread
                counter = 0;
                config.entryId = entryIds[counter];
                [_player changeConfiguration:config];

            });
        });
    }];
    
    // 5b. Set the delegate if you did not use the completion handler initializer
    //    urlSession.delegate = self;
    
    // 6. Finally, call resume on your task.
    [dataTask resume];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self presentViewController:self.player animated:YES completion:nil];
}

@end