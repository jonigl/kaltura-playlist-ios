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
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)test {
    NSLog(@"REQUEST");
    /*
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://localhost:8080/api/playlist/radiox/lunes"]];
    [request setHTTPMethod:@"GET"];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        //     NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        NSDictionary *newJSON = [NSJSONSerialization JSONObjectWithData:data
                                                                options:0
                                                                  error:nil];
        entryIds = [newJSON objectForKey:@"playlist"];
        counter = 0;
        // Video Entry
        config.entryId = entryIds[counter];
        NSLog(@"requestReply: %@", newJSON);
    }] resume];
    
    */
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://localhost:8080/api/playlist/radiox/lunes"]];
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:nil
                                                        error:nil];
    NSDictionary *newJSON = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:nil];
    entryIds = [newJSON objectForKey:@"playlist"];
    counter = 0;
    // Video Entry
    config.entryId = entryIds[counter];
    NSLog(@"requestReply: %@", newJSON);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)kPlayer:(KPViewController *)player playerPlaybackStateDidChange:(KPMediaPlaybackState)state{
    NSLog(@"player state %ld", (long)state);
    if (state == KPMediaPlaybackStateEnded && counter < [entryIds count]-1){
        counter = counter + 1;
        NSLog(@"entry played");
        [player changeMedia:entryIds[counter]];
    }
}

- (KPViewController *)player {
    if (!_player) {
        // Account Params
        config = [[KPPlayerConfig alloc] initWithServer:@"http://vodgc.com"
                                               uiConfID:@"23448994"
                                              partnerId:@"109"];
        [self test];
        //counter = 0;
//        entryIds = @[@"0_afssmo0b",@"0_fms0o85z", @"0_0yazfkud", @"0_o61ax56a"];
        // Video Entry
        //config.entryId = entryIds[counter];
        //config.entryId = @"0_adsvymov";
        
        //        [config setEntryId:@"0_79j3ff7e"];
        
        // Setting this property will cache the html pages in the limit size
        config.cacheSize = 0.8;
        
        [config addConfigKey:@"autoPlay" withValue:@"true"];
        [self hideHTMLControls];
        _player = [[KPViewController alloc] initWithConfiguration:config];
        NSLog(@"Player configured");
        
    }
    return _player;
}

- (void)hideHTMLControls {
    // chromeless config
    // Set AutoPlay as configuration on player (same like setting a flashvar)
    [config addConfigKey:@"controlBarContainer.plugin" withValue:@"false"];
    // whitout poster
    [config addConfigKey:@"EmbedPlayer.HidePosterOnStart" withValue:@"true"];
    [config addConfigKey:@"topBarContainer.plugin" withValue:@"false"];
    [config addConfigKey:@"largePlayBtn.plugin" withValue:@"false"];
    [config addConfigKey:@"loadingSpinner.plugin" withValue:@"false"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self presentViewController:self.player animated:YES completion:nil];
}

@end