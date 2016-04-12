//
//  ViewController.m
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 3/21/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"
#import "Current.h"
#import "Playlist.h"
#import <KALTURAPlayerSDK/KPViewController.h>


@interface ViewController () <KPViewControllerDelegate>
@property (retain, nonatomic) KPViewController *player;
@property (retain, nonatomic) KPPlayerConfig *config;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Playlist *playlist;
@end

NSURL *_url;
int const noInternetPopUpTag = 1;
int const loadingPopUpTag = 2;
int const noInternetLabelTag = 3;
int const spinnerTag = 4;

@implementation ViewController {
    BOOL isFirstTime;
    BOOL isRequestSent;
}




- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    isFirstTime = YES;
    isRequestSent = NO;
    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    NetworkStatus remoteHostStatus = [self.internetReachability currentReachabilityStatus];
    if(remoteHostStatus != NotReachable) {
        NSLog(@"Internet access is available");
        // Get playlist from API
        [self getPlaylist];
    }else{
        NSLog(@"No internet connection");
    }
    // I delegate the player
    self.player.delegate = self;
    
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    NetworkStatus remoteHostStatus = [self.internetReachability currentReachabilityStatus];
    if(remoteHostStatus == NotReachable) {
        [[self.view viewWithTag:noInternetPopUpTag] setHidden:NO];
        [[self.view viewWithTag:noInternetLabelTag] setHidden:NO];
        NSLog(@"No internet connection");
    }else{
        [[self.view viewWithTag:noInternetPopUpTag] setHidden:YES];
        [[self.view viewWithTag:noInternetLabelTag] setHidden:YES];
        NSLog(@"Internet access is available");
        if (![Playlist thePlaylist].isSetEntries && !isRequestSent){
            // Get playlist from API
            [self getPlaylist];
        }
    }
    /*else if (remoteHostStatus == ReachableViaWiFi) {
        noInternetPopUp.hidden = YES;
        noInternetLabel.hidden = YES;
        NSLog(@"wifi");
    }
    else if (remoteHostStatus == ReachableViaWWAN) {
        noInternetPopUp.hidden = YES;
        noInternetLabel.hidden = YES;
        NSLog(@"cell");
    }*/
}

+(void)setURLScheme: (NSURL *)urlScheme{
    _url = urlScheme;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (KPViewController *)player {
    if (!_player) {
        _player = [KPViewController alloc];
        //_player = [[KPViewController alloc] initWithConfiguration:config];
    }
    return _player;
}


-(void)configPlayerWithEntryID:(NSString *) entryID{
    // Account Params
    _config = [[KPPlayerConfig alloc] initWithServer:@"http://vodgc.com"
                                           uiConfID:@"23448994"
                                          partnerId:@"109"];
    // Setting this property will cache the html pages in the limit size
    // config.cacheSize = 0.8;
    [_config setEntryId: entryID];
    [_config addConfigKey:@"autoPlay" withValue:@"true"];
    [self hideHTMLControls];
    NSLog(@"PLAYER CONFIGURED");
}

// chromeless config
- (void)hideHTMLControls {
    // Set AutoPlay as configuration on player (same like setting a flashvar)
    [_config addConfigKey:@"controlBarContainer.plugin" withValue:@"false"];
    // whitout poster
    [_config addConfigKey:@"EmbedPlayer.HidePosterOnStart" withValue:@"true"];
    [_config addConfigKey:@"topBarContainer.plugin" withValue:@"false"];
    [_config addConfigKey:@"largePlayBtn.plugin" withValue:@"false"];
    [_config addConfigKey:@"loadingSpinner.plugin" withValue:@"false"];
    NSLog(@"HTML Controls hid");
}

- (void)kPlayer:(KPViewController *)player playerPlaybackStateDidChange:(KPMediaPlaybackState)state{
    [self logPlaybackState: state];
    //if (state == KPMediaPlaybackStateEnded && counter < [entryIds count]-1){
    if (state == KPMediaPlaybackStateEnded && ![[Playlist thePlaylist] isLastEntrie]){
        //counter = counter + 1;
        NSLog(@"NEXT VIDEO");
        [[Playlist thePlaylist] nextEntrie];
        [player changeMedia:[[Playlist thePlaylist] getCurrentEntrieID]];
        //[player changeMedia:[entryIds[counter]objectForKey:@"id"]];
    }
    if (state == KPMediaPlaybackStatePaused && ![[Playlist thePlaylist] isLastEntrie]){
    //    [player.playerController play];
    }
    
}


- (void)kPlayer:(KPViewController *)player playerLoadStateDidChange:(KPMediaLoadState)state{
    NSLog(@"PLAYER LOAD STATE DID CHANGE TO: %ld", (long)state);
    if (state == 1 && isFirstTime) {
        isFirstTime = NO;
        [_player.playerController seek:[[Playlist thePlaylist] getCurrentOffset]];
        [_player.playerController play];
    }
}

// Get playlist from API
-(void)getPlaylist {
    isRequestSent = YES;
    NSLog(@"GET REQUEST PLAYLIST");
    [[self.view viewWithTag:loadingPopUpTag] setHidden:NO];
    [[self.view viewWithTag:spinnerTag] setHidden:NO];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    // 1. The web address & headers
    //NSString *webAddress = @"http://devcr.com.ar:8080/api/playlist/radiox/lunes";
    //NSString *webAddress = @"http://127.0.0.1:8080/api/test";
    NSString *webAddress = @"http://devcr.com.ar:8080/api/test";
    
    
    // 2. An NSURL wrapped in an NSURLRequest
    NSURL* url = [NSURL URLWithString:webAddress];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 3. An NSURLSession Configuration
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // 4. The URLSession itself.
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    
    // 5. A session task: NSURLSessionDataTask or NSURLSessionDownloadTask
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [[self.view viewWithTag:loadingPopUpTag] setHidden:YES];
                [[self.view viewWithTag:spinnerTag] setHidden:YES];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            });
        });
        if (error == nil){
            NSError *parseError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            NSLog(@"%@", json);
            NSArray *entryIds = [json objectForKey:@"playlist"];
            [[Playlist thePlaylist] setEntries:entryIds];
            double timestamp = [[json objectForKey:@"timestamp"] doubleValue] /1000;
            [[Playlist thePlaylist] setTimestamp:timestamp];
            [[Playlist thePlaylist] findCurrent];
            
            //current = [self getCurrentEntry];
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    //Run UI Updates
                    //Background Thread
                    NSString *entryID = [[Playlist thePlaylist] getCurrentEntrieID];
                    [self configPlayerWithEntryID: entryID];
                    [_player changeConfiguration:_config];
                });
            });
        }else{
            NSLog(@"There was a problem while a response was expected");
            isRequestSent = NO;
        }
        
    }];
    // 5b. Set the delegate if you did not use the completion handler initiali
    //    urlSession.delegate = self;
    // 6. Finally, call resume on your task.
    [dataTask resume];
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


-(void)drawNoInternetPopUpOverlay{
    int width = 160, height = 160;
    int statusBarHeight= [UIApplication sharedApplication].statusBarFrame.size.height;
    CGRect noInternetPopUpFrame = CGRectMake(CGRectGetMidX(self.view.frame) - (width / 2.0), CGRectGetMidY(self.view.frame) + statusBarHeight - (height / 2.0), width,height);
    UIView *noInternetPopUp = [[UIView alloc] initWithFrame:noInternetPopUpFrame];
    UILabel *noInternetLabel = [[UILabel alloc] initWithFrame:noInternetPopUpFrame];
    [noInternetPopUp setTag:noInternetPopUpTag];
    [noInternetLabel setTag:noInternetLabelTag];
    
    noInternetPopUp.layer.cornerRadius = 10;
    noInternetPopUp.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    noInternetPopUp.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5];
    
    noInternetLabel.text = @"No internet \nconnection";
    noInternetLabel.lineBreakMode = NSLineBreakByWordWrapping;
    noInternetLabel.numberOfLines = 0;
    noInternetLabel.textAlignment = NSTextAlignmentCenter;
    noInternetLabel.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    noInternetLabel.textColor = [UIColor whiteColor];
    
    NetworkStatus remoteHostStatus = [self.internetReachability currentReachabilityStatus];
    if(remoteHostStatus == NotReachable) {
        noInternetLabel.hidden = NO;
        noInternetPopUp.hidden = NO;
    }else{
        noInternetLabel.hidden = YES;
        noInternetPopUp.hidden = YES;
    }
    [self.view addSubview:noInternetPopUp];
    [self.view addSubview:noInternetLabel];
    //[noInternetPopUp release];
}

-(void)drawLoadingPopUpOverlay{
    int width = 120, height = 120;
    int statusBarHeight= [UIApplication sharedApplication].statusBarFrame.size.height;
    CGRect loadingPopUpFrame = CGRectMake(CGRectGetMidX(self.view.frame) - (width / 2.0), CGRectGetMidY(self.view.frame) + statusBarHeight - (height / 2.0), width,height);
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    CGRect spinnerFrame = spinner.frame;
    spinnerFrame.origin.x = self.view.frame.size.width / 2 - spinnerFrame.size.width / 2;
    spinnerFrame.origin.y = self.view.frame.size.height / 2 + statusBarHeight - spinnerFrame.size.height / 2;
    spinner.frame = spinnerFrame;
    [spinner setTag:spinnerTag];
    UIView *loadingPopUp =[[UIView alloc] initWithFrame:loadingPopUpFrame];
    [loadingPopUp setTag:loadingPopUpTag];
    loadingPopUp.layer.cornerRadius = 10;
    loadingPopUp.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    loadingPopUp.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.5];
    loadingPopUp.hidden = YES;
    spinner.hidden = YES;
 
    [self.view addSubview:loadingPopUp];
    [self.view addSubview:spinner];
    [spinner startAnimating];
    //[loadingPopUp release];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [super viewDidAppear:animated];
    self.player.view.frame = (CGRect){CGPointZero, _playerHolderView.frame.size};
    [self.player loadPlayerIntoViewController:self];
    [_playerHolderView addSubview:_player.view];
    [self drawNoInternetPopUpOverlay];
    [self drawLoadingPopUpOverlay];
    /*
    if (isRequestSent){
        [[self.view viewWithTag:loadingPopUpTag] setHidden:NO];
        [[self.view viewWithTag:spinnerTag] setHidden:NO];
    }
     */
    //[self presentViewController:self.player animated:YES completion:nil];
    
}

@end