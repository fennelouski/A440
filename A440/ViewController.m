//
//  ViewController.m
//  A440
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "ViewController.h"
#import "UIColor+AppColors.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([[UIApplication sharedApplication] statusBarFrame].size.height > 20.0f) ? [UIScreen mainScreen].bounds.size.height - 20.0f : [UIScreen mainScreen].bounds.size.height)
#define ANIMATION_DURATION 0.35f
#define SHORTER_SIDE ((kScreenWidth < kScreenHeight) ? kScreenWidth : kScreenHeight)
#define LONGER_SIDE ((kScreenWidth > kScreenHeight) ? kScreenWidth : kScreenHeight)
#define BUTTON_SCALE 0.8f
#define BUFFER (kScreenWidth * 0.05f)

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastFile = [defaults objectForKey:@"lastFile"];
    if (!lastFile) [defaults setObject:@"sineWave" forKey:@"lastFile"];
    
    CALayer *layer = [CALayer layer];
    layer.frame = self.view.layer.frame;
    layer.contents = (id)[UIImage imageNamed:@"background.png"].CGImage;
    [self.view.layer addSublayer:layer];
    CAGradientLayer *gradientOverlay = [self lightBlueGradient];
    gradientOverlay.frame = CGRectMake(0.0f, 0.0f, kScreenWidth, kScreenHeight);
    gradientOverlay.opacity = 1.0f;
    [self.view.layer addSublayer:gradientOverlay];
    
    [self.view addSubview:self.pianoButton];
    [self.view addSubview:self.violinButton];
    [self.view addSubview:self.frenchHornButton];
    [self.view addSubview:self.sineWaveButton];
}

- (CAGradientLayer *)lightBlueGradient {
    NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor skyBlue].CGColor, [UIColor darkSkyBlue].CGColor, nil];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComps = [gregorianCalendar components:(NSCalendarUnitHour) fromDate: [NSDate date]];
    NSInteger hour = [dateComps hour];
    
    if (hour < 6 || hour > 22) {
        colors = @[(id)[UIColor colorWithRed:0.03f green:0.0f blue:0.53f alpha:1.0f].CGColor,
                   (id)[UIColor colorWithRed:0.0f green:0.0f blue:0.3f alpha:1.0f].CGColor];
    }
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0f];
    NSNumber *stopTwo = [NSNumber numberWithFloat:0.5f];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
}

#pragma mark - Subviews

- (UIView *)pianoButton {
    if (!_pianoButton) {
        _pianoButton = [[UIView alloc] initWithFrame:CGRectMake(BUFFER,
                                                                kStatusBarHeight + BUFFER,
                                                                (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                ((kScreenHeight - kStatusBarHeight)/2.0f) * BUTTON_SCALE)];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pianoButtonTouched)];
        [_pianoButton addGestureRecognizer:tapGesture];
        UIImage *pianoImage = [UIImage imageNamed:@"Piano_de_Cauda_de_Manuel_Inocêncio_Liberato_dos_Santos"];
        UIImageView *pianoImageView = [[UIImageView alloc] initWithImage:pianoImage];
        [pianoImageView setFrame:_pianoButton.bounds];
        [pianoImageView setContentMode:UIViewContentModeScaleAspectFit];
        [_pianoButton addSubview:pianoImageView];
    }
    
    return _pianoButton;
}

- (UIView *)violinButton {
    if (!_violinButton) {
        _violinButton = [[UIView alloc] initWithFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                                                 kStatusBarHeight + BUFFER,
                                                                 (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                 ((kScreenHeight - kStatusBarHeight)/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(violinButtonTouched)];
        [_violinButton addGestureRecognizer:tapGesture];
        UIImage *violinImage = [UIImage imageNamed:@"Violin_Geige"];
        UIImageView *violinImageView = [[UIImageView alloc] initWithImage:violinImage];
        [violinImageView setFrame:_violinButton.bounds];
        [violinImageView setContentMode:UIViewContentModeScaleAspectFit];
        [_violinButton addSubview:violinImageView];
    }
    
    return _violinButton;
}

- (UIView *)frenchHornButton {
    if (!_frenchHornButton) {
        _frenchHornButton = [[UIView alloc] initWithFrame:CGRectMake(BUFFER,
                                                               ((kScreenHeight - kStatusBarHeight)/2.0f) + kStatusBarHeight,
                                                               (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                               ((kScreenHeight - kStatusBarHeight)/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(frenchHornButtonTouched)];
        [_frenchHornButton addGestureRecognizer:tapGesture];
        UIImage *frenchHornImage = [UIImage imageNamed:@"frenchHorn"];
        UIImageView *frenchHornImageView = [[UIImageView alloc] initWithImage:frenchHornImage];
        [frenchHornImageView setFrame:_frenchHornButton.bounds];
        [frenchHornImageView setContentMode:UIViewContentModeScaleAspectFit];
        [_frenchHornButton addSubview:frenchHornImageView];
    }
    
    return _frenchHornButton;
}

- (UIView *)sineWaveButton {
    if (!_sineWaveButton) {
        _sineWaveButton = [[UIView alloc] initWithFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                                                   ((kScreenHeight - kStatusBarHeight)/2.0f) + kStatusBarHeight,
                                                                   (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                   ((kScreenHeight - kStatusBarHeight)/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sineWaveButtonTouched)];
        [_sineWaveButton addGestureRecognizer:tapGesture];
        UIImage *sineWaveImage = [UIImage imageNamed:@"Sine Wave Image"];
        UIImageView *sineWaveImageView = [[UIImageView alloc] initWithImage:sineWaveImage];
        [sineWaveImageView setFrame:_sineWaveButton.bounds];
        [sineWaveImageView setContentMode:UIViewContentModeScaleAspectFit];
        [_sineWaveButton addSubview:sineWaveImageView];

    }
    
    return _sineWaveButton;
}

#pragma mark - Audio Player

- (AVAudioPlayer *)audioPlayer {
    if (!_audioPlayer) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *lastFile = [defaults objectForKey:@"lastFile"];
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@.wav",
                                   [[NSBundle mainBundle] resourcePath], lastFile];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL
                                                                  error:nil];
    }
    
    return _audioPlayer;
}

#pragma mark - Button Actions

- (void)pianoButtonTouched {
    if (self.pianoButton.tag == 1) {
        NSLog(@"Stop Piano");
        [self.audioPlayer stop];
        [self.frenchHornButton setTag:0];
        [self.pianoButton setTag:0];
        [self.violinButton setTag:0];
        [self.sineWaveButton setTag:0];
    }
    
    else {
        [self playAudioFile:@"piano"];
        [self.frenchHornButton setTag:0];
        [self.pianoButton setTag:1];
        [self.violinButton setTag:0];
        [self.sineWaveButton setTag:0];
    }
}

- (void)violinButtonTouched {
    if (self.violinButton.tag == 1) {
        NSLog(@"Stop Violin");
        [self.audioPlayer stop];
        [self.frenchHornButton setTag:0];
        [self.pianoButton setTag:0];
        [self.violinButton setTag:0];
        [self.sineWaveButton setTag:0];
    }
    
    else {
        [self playAudioFile:@"violin"];
        [self.frenchHornButton setTag:0];
        [self.pianoButton setTag:0];
        [self.violinButton setTag:1];
        [self.sineWaveButton setTag:0];
    }
}

- (void)frenchHornButtonTouched {
    if (self.frenchHornButton.tag == 1) {
        NSLog(@"Stop frenchHorn");
        [self.audioPlayer stop];
        [self.frenchHornButton setTag:0];
        [self.pianoButton setTag:0];
        [self.violinButton setTag:0];
        [self.sineWaveButton setTag:0];
    }
    
    else {
        [self playAudioFile:@"frenchHorn"];
        [self.frenchHornButton setTag:1];
        [self.pianoButton setTag:0];
        [self.violinButton setTag:0];
        [self.sineWaveButton setTag:0];
    }
}

- (void)sineWaveButtonTouched {
    if (self.sineWaveButton.tag == 1) {
        NSLog(@"Stop Sine Wave");
        [self.audioPlayer stop];
        [self.frenchHornButton setTag:0];
        [self.pianoButton setTag:0];
        [self.violinButton setTag:0];
        [self.sineWaveButton setTag:0];
    }
    
    else {
        [self playAudioFile:@"sineWave"];
        [self.frenchHornButton setTag:0];
        [self.pianoButton setTag:0];
        [self.violinButton setTag:0];
        [self.sineWaveButton setTag:1];
    }
}

#pragma mark - Play Audio File

- (void)playAudioFile:(NSString *)fileName {
    NSLog(@"Play %@", fileName);
    
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer stop];
    }
    
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@.wav",
                               [[NSBundle mainBundle] resourcePath], fileName];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL
                                                              error:nil];
    self.audioPlayer.numberOfLoops = -1; //Infinite
    
    [self.audioPlayer play];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
