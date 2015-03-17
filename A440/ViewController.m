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
#define ANIMATION_DURATION 0.25f
#define SHORTER_SIDE ((kScreenWidth < kScreenHeight) ? kScreenWidth : kScreenHeight)
#define LONGER_SIDE ((kScreenWidth > kScreenHeight) ? kScreenWidth : kScreenHeight)
#define BUTTON_SCALE 0.8f
#define BUFFER (kScreenWidth * 0.05f)
#define AVAILABLE_HEIGHT (kScreenHeight - kStatusBarHeight - ((self.adView.bannerLoaded) ? self.adView.frame.size.height : 0.0f))
#define CORNER_RADIUS_RATIO 8.0f

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
    gradientOverlay.frame = CGRectMake(0.0f, 0.0f, LONGER_SIDE + 20.0f, LONGER_SIDE + 20.0f);
    gradientOverlay.opacity = 1.0f;
    [self.view.layer addSublayer:gradientOverlay];
    
    [self.view addSubview:self.pianoButton];
    [self.view addSubview:self.violinButton];
    [self.view addSubview:self.frenchHornButton];
    [self.view addSubview:self.sineWaveButton];
    [self.view addSubview:self.adView];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self  selector:@selector(updateViews)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    [nc addObserver:self selector:@selector(updateViews) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
}

- (void)updateViews {
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self layoutButtons];
        [self.pianoImageView setFrame:self.pianoButton.bounds];
        [self.violinImageView setFrame:self.violinButton.bounds];
        [self.frenchHornImageView setFrame:self.frenchHornButton.bounds];
        [self.sineWaveImageView setFrame:self.sineWaveButton.bounds];
        
        if (self.bannerShouldLayout && self.adView.bannerLoaded) {
            [self.adView setCenter:CGPointMake(kScreenWidth/2.0f, kScreenHeight - [self.adView frame].size.height/2.0f)];
        }
        
        else if (!self.adView.bannerLoaded) {
            [self.adView setCenter:CGPointMake(kScreenWidth/2.0f, kScreenHeight + self.adView.frame.size.height)];
        }
    }];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        self.adView.currentContentSizeIdentifier =
        ADBannerContentSizeIdentifierLandscape;
    else
        self.adView.currentContentSizeIdentifier =
        ADBannerContentSizeIdentifierPortrait;
}


- (void)layoutButtons {
    float row1YBuffer = -10.0f;
    float row2YBuffer = 10.0f;
    if (kStatusBarHeight > 0.0f) {
        row1YBuffer = 0.0f;
        row2YBuffer = 20.0f;
    }
    [self.pianoButton setFrame:CGRectMake(BUFFER,
                                          kStatusBarHeight + BUFFER + row1YBuffer,
                                          (kScreenWidth/2.0f) * BUTTON_SCALE,
                                          (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
    [self.violinButton setFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                           kStatusBarHeight + BUFFER + row1YBuffer,
                                           (kScreenWidth/2.0f) * BUTTON_SCALE,
                                           (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
    [self.frenchHornButton setFrame:CGRectMake(BUFFER,
                                               (AVAILABLE_HEIGHT/2.0f) + kStatusBarHeight + row2YBuffer,
                                               (kScreenWidth/2.0f) * BUTTON_SCALE,
                                               (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
    [self.sineWaveButton setFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                             (AVAILABLE_HEIGHT/2.0f) + kStatusBarHeight + row2YBuffer,
                                             (kScreenWidth/2.0f) * BUTTON_SCALE,
                                             (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
    float scale = 0.98f;
    [self scaleView:self.pianoButton to:scale];
    [self scaleView:self.violinButton to:scale];
    [self scaleView:self.frenchHornButton to:scale];
    [self scaleView:self.sineWaveButton to:scale];
}

- (void)scaleView:(A4InstrumentView *)view to:(float)scale {
    CGPoint originalCenter = view.center;
    CGRect frame = view.frame;
    frame.size.height *= scale;
    frame.size.width *= scale;
    [view setFrame:frame];
    [view setCenter:originalCenter];
    
    [self setUpViewShadow:view];
    [view.gradientLayer setCornerRadius:view.layer.cornerRadius];
    [view.gradientLayer setFrame:view.bounds];
}

- (void)setUpViewShadow:(UIView *)view {
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds
                                                          cornerRadius:view.frame.size.height / CORNER_RADIUS_RATIO];
    [view.layer setMasksToBounds:NO];
    [view.layer setShadowColor:[UIColor blackColor].CGColor];
    [view.layer setShadowOffset:CGSizeMake(-5.0f, 8.0f)];
    [view.layer setCornerRadius:view.frame.size.height / CORNER_RADIUS_RATIO];
    [view.layer setShadowRadius:8.0f];
    [view.layer setShadowOpacity:0.25f];
    view.layer.shadowPath = shadowPath.CGPath;
}

- (CAGradientLayer *)lightBlueGradient {
    NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor appColor2].CGColor, [UIColor appColor1].CGColor, nil];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComps = [gregorianCalendar components:(NSCalendarUnitHour) fromDate: [NSDate date]];
    NSInteger hour = [dateComps hour];
    
    if (hour < 6 || hour > 22) {
        colors = @[(id)[UIColor appColor1].CGColor,
                   (id)[UIColor appColor3].CGColor];
    }
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.3f];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0f];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
}

#pragma mark - Subviews

- (A4InstrumentView *)pianoButton {
    if (!_pianoButton) {
        _pianoButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(BUFFER,
                                                                kStatusBarHeight + BUFFER,
                                                                (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pianoButtonTouched)];
        [_pianoButton addGestureRecognizer:tapGesture];
        [_pianoButton addSubview:self.pianoImageView];
        
        [_pianoButton setBackgroundColor:[UIColor appColor]];
    }
    
    return _pianoButton;
}

- (UIImageView *)pianoImageView {
    if (!_pianoImageView) {
        UIImage *pianoImage = [UIImage imageNamed:@"Piano_de_Cauda_de_Manuel_Inocêncio_Liberato_dos_Santos"];
        _pianoImageView = [[UIImageView alloc] initWithImage:pianoImage];
        [_pianoImageView setFrame:_pianoButton.bounds];
        [_pianoImageView setContentMode:UIViewContentModeScaleAspectFit];
    }
    
    return _pianoImageView;
}

- (A4InstrumentView *)violinButton {
    if (!_violinButton) {
        _violinButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                                                 kStatusBarHeight + BUFFER,
                                                                 (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                 (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(violinButtonTouched)];
        [_violinButton addGestureRecognizer:tapGesture];
        [_violinButton addSubview:self.violinImageView];
        
        [_violinButton setBackgroundColor:[UIColor appColor]];
    }
    
    return _violinButton;
}

- (UIImageView *)violinImageView {
    if (!_violinImageView) {
        UIImage *violinImage = [UIImage imageNamed:@"Violin_Geige"];
        _violinImageView = [[UIImageView alloc] initWithImage:violinImage];
        [_violinImageView setFrame:_violinButton.bounds];
        [_violinImageView setContentMode:UIViewContentModeScaleAspectFit];
    }
    
    return _violinImageView;
}

- (A4InstrumentView *)frenchHornButton {
    if (!_frenchHornButton) {
        _frenchHornButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(BUFFER,
                                                               (AVAILABLE_HEIGHT/2.0f) + kStatusBarHeight,
                                                               (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                               (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(frenchHornButtonTouched)];
        [_frenchHornButton addGestureRecognizer:tapGesture];
        [_frenchHornButton addSubview:self.frenchHornImageView];

        [_frenchHornButton setBackgroundColor:[UIColor appColor]];
    }
    
    return _frenchHornButton;
}

- (UIImageView *)frenchHornImageView {
    if (!_frenchHornImageView) {
        UIImage *frenchHornImage = [UIImage imageNamed:@"FrenchHorn"];
        _frenchHornImageView = [[UIImageView alloc] initWithImage:frenchHornImage];
        [_frenchHornImageView setFrame:_frenchHornButton.bounds];
        [_frenchHornImageView setContentMode:UIViewContentModeScaleAspectFit];
    }
    
    return _frenchHornImageView;
}

- (A4InstrumentView *)sineWaveButton {
    if (!_sineWaveButton) {
        _sineWaveButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                                                   (AVAILABLE_HEIGHT/2.0f) + kStatusBarHeight,
                                                                   (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                   (AVAILABLE_HEIGHT/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sineWaveButtonTouched)];
        [_sineWaveButton addGestureRecognizer:tapGesture];
        [_sineWaveButton addSubview:self.sineWaveImageView];
        
        [_sineWaveButton setBackgroundColor:[UIColor appColor]];
    }
    
    return _sineWaveButton;
}

- (UIImageView *)sineWaveImageView {
    if (!_sineWaveImageView) {
        UIImage *sineWaveImage = [UIImage imageNamed:@"Sine Wave Image"];
        _sineWaveImageView = [[UIImageView alloc] initWithImage:sineWaveImage];
        [_sineWaveImageView setFrame:_sineWaveButton.bounds];
        [_sineWaveImageView setContentMode:UIViewContentModeScaleAspectFit];
    }
    
    return _sineWaveImageView;
}

- (ADBannerView *)adView {
    if (!_adView) {
        _adView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
        [_adView setAutoresizingMask:UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleBottomMargin];
        [_adView setDelegate:self];
        self.bannerShouldLayout = YES;
    }
    
    return _adView;
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
        [self resetButtons];
    }
    
    else {
        [self playAudioFile:@"piano"];
        [self resetButtons];
        [self.pianoButton setTag:1];
    }
    
    [self animateButtons];
}

- (void)violinButtonTouched {
    if (self.violinButton.tag == 1) {
        NSLog(@"Stop Violin");
        [self.audioPlayer stop];
        [self resetButtons];
    }
    
    else {
        [self playAudioFile:@"violin"];
        [self resetButtons];
        [self.violinButton setTag:1];
    }
    
    [self animateButtons];
}

- (void)frenchHornButtonTouched {
    if (self.frenchHornButton.tag == 1) {
        NSLog(@"Stop frenchHorn");
        [self.audioPlayer stop];
        [self resetButtons];
    }
    
    else {
        [self playAudioFile:@"frenchHorn"];
        [self resetButtons];
        [self.frenchHornButton setTag:1];
    }
    
    [self animateButtons];
}

- (void)sineWaveButtonTouched {
    if (self.sineWaveButton.tag == 1) {
        NSLog(@"Stop Sine Wave");
        [self.audioPlayer stop];
        [self resetButtons];
    }
    
    else {
        [self playAudioFile:@"sineWave"];
        [self resetButtons];
        [self.sineWaveButton setTag:1];
    }
    
    [self animateButtons];
}

- (void)resetButtons {
    [self.frenchHornButton setTag:0];
    [self.pianoButton setTag:0];
    [self.violinButton setTag:0];
    [self.sineWaveButton setTag:0];
}

- (void)animateButtons {
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.frenchHornButton.gradientLayer setGeometryFlipped:self.frenchHornButton.tag];
        [self.sineWaveButton.gradientLayer setGeometryFlipped:self.sineWaveButton.tag];
        [self.violinButton.gradientLayer setGeometryFlipped:self.violinButton.tag];
        [self.pianoButton.gradientLayer setGeometryFlipped:self.pianoButton.tag];
    }];
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

// I wish this worked...
- (void)fadeAudioOut:(NSNumber *)volume {
    float volumeAsFloat = [volume floatValue];
    volumeAsFloat -= 0.03f;
    if (volumeAsFloat > 0.0f) {
        [self performSelector:@selector(fadeAudioOut:) withObject:[NSNumber numberWithFloat:volumeAsFloat] afterDelay:0.01f];
    }
    
    else {
        [self.audioPlayer stop];
        [self.audioPlayer setVolume:1.0f];
    }
}

#pragma mark - Ad Banner Delegate

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    if (!willLeave) {
        [self fadeAudioOut:[NSNumber numberWithFloat:self.audioPlayer.volume]];
        [self resetButtons];
        [self updateViews];
    }
    
    return YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [self updateViews];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
//    self.bannerShouldLayout = YES;
    [self updateViews];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"iAD error: didFailToReceiveAdWithError: %@", error);
    
    [self updateViews];
}

#pragma mark - gradient

- (CAGradientLayer *)shadowGradient {
    NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:1.0f alpha:0.41f].CGColor,
                       (id)[UIColor colorWithWhite:0.9f alpha:0.0f].CGColor,
                       (id)[UIColor clearColor].CGColor,
                       (id)[UIColor colorWithWhite:0.0f alpha:0.2f].CGColor, nil];
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0f];
    NSNumber *stopTwo = [NSNumber numberWithFloat:0.15f];
    NSNumber *stopThree = [NSNumber numberWithFloat:0.75f];
    NSNumber *stopFour = [NSNumber numberWithFloat:1.0f];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, stopThree, stopFour, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
