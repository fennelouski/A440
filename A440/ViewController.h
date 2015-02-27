//
//  ViewController.h
//  A440
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <iAd/iAd.h>

@interface ViewController : UIViewController <ADBannerViewDelegate>

@property (nonatomic, strong) UIView *pianoButton, *violinButton, *sineWaveButton, *frenchHornButton;
@property (nonatomic, strong) UIImageView *pianoImageView, *violinImageView, *frenchHornImageView, *sineWaveImageView;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) ADBannerView *adView;
@property BOOL bannerShouldLayout;

@end

