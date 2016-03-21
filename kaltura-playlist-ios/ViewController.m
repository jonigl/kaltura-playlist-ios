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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)kPlayer:(KPViewController *)_player playerPlaybackStateDidChange:(KPMediaPlaybackState)state{
    NSLog(@"player state %ld", (long)state);
    if (state == KPMediaPlaybackStateEnded){
        NSLog(@"entry played");
    }
}

- (KPViewController *)player {
    if (!_player) {
        // Account Params
        config = [[KPPlayerConfig alloc] initWithServer:@"http://vodgc.com"
                                               uiConfID:@"23448994"
                                              partnerId:@"109"];
        // Video Entry
        config.entryId = @"0_0yazfkud";
        //        [config setEntryId:@"0_79j3ff7e"];
        
        // Setting this property will cache the html pages in the limit size
        //        config.cacheSize = 0.8;
        
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
    [config addConfigKey:@"topBarContainer.plugin" withValue:@"false"];
    [config addConfigKey:@"largePlayBtn.plugin" withValue:@"false"];
    [config addConfigKey:@"loadingSpinner.plugin" withValue:@"false"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self presentViewController:self.player animated:YES completion:nil];
}

@end