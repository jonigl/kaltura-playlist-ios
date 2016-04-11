//
//  ViewController.h
//  kaltura-playlist-ios
//
//  Created by Jonathan Lowenstern on 3/21/16.
//  Copyright © 2016 Jonathan Lowenstern. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

+ (void)setURLScheme:(NSURL *)urlScheme;
@property (weak, nonatomic) IBOutlet UIView
*playerHolderView;

@end

