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
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define ANIMATION_DURATION 0.25f
#define SHORTER_SIDE ((kScreenWidth < kScreenHeight) ? kScreenWidth : kScreenHeight)
#define LONGER_SIDE ((kScreenWidth > kScreenHeight) ? kScreenWidth : kScreenHeight)
#define BUTTON_SCALE 0.8f
#define BUFFER (kScreenWidth * 0.05f)
#define CORNER_RADIUS_RATIO 8.0f

@interface ViewController ()

@property (nonatomic) CGFloat topSafeAreaInset;
@property (nonatomic) CGFloat bottomSafeAreaInset;

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

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(updateViews) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (@available(iOS 11.0, *)) {
        self.topSafeAreaInset = self.view.safeAreaInsets.top;
        self.bottomSafeAreaInset = self.view.safeAreaInsets.bottom;
    } else {
        self.topSafeAreaInset = self.topLayoutGuide.length;
        self.bottomSafeAreaInset = self.bottomLayoutGuide.length;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateViews];
    } completion:nil];
}

- (void)updateViews {
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self layoutButtons];
        [self.pianoImageView setFrame:self.pianoButton.bounds];
        [self.violinImageView setFrame:self.violinButton.bounds];
        [self.frenchHornImageView setFrame:self.frenchHornButton.bounds];
        [self.sineWaveImageView setFrame:self.sineWaveButton.bounds];
    }];
}


- (void)layoutButtons {
    CGFloat availableHeight = kScreenHeight - self.topSafeAreaInset - self.bottomSafeAreaInset;
    CGFloat row1YBuffer = 0.0f;
    CGFloat row2YBuffer = 20.0f;

    [self.pianoButton setFrame:CGRectMake(BUFFER,
                                          self.topSafeAreaInset + BUFFER + row1YBuffer,
                                          (kScreenWidth/2.0f) * BUTTON_SCALE,
                                          (availableHeight/2.0f) * BUTTON_SCALE)];
    [self.violinButton setFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                           self.topSafeAreaInset + BUFFER + row1YBuffer,
                                           (kScreenWidth/2.0f) * BUTTON_SCALE,
                                           (availableHeight/2.0f) * BUTTON_SCALE)];
    [self.frenchHornButton setFrame:CGRectMake(BUFFER,
                                               (availableHeight/2.0f) + self.topSafeAreaInset + row2YBuffer,
                                               (kScreenWidth/2.0f) * BUTTON_SCALE,
                                               (availableHeight/2.0f) * BUTTON_SCALE)];
    [self.sineWaveButton setFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                             (availableHeight/2.0f) + self.topSafeAreaInset + row2YBuffer,
                                             (kScreenWidth/2.0f) * BUTTON_SCALE,
                                             (availableHeight/2.0f) * BUTTON_SCALE)];
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
        CGFloat availableHeight = kScreenHeight - self.topSafeAreaInset - self.bottomSafeAreaInset;
        _pianoButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(BUFFER,
                                                                self.topSafeAreaInset + BUFFER,
                                                                (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                (availableHeight/2.0f) * BUTTON_SCALE)];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(tapped:)];
        [_pianoButton addGestureRecognizer:tapGesture];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(longPressed:)];
        [longPress setMinimumPressDuration:0.25f];
        [_pianoButton addGestureRecognizer:longPress];
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
        CGFloat availableHeight = kScreenHeight - self.topSafeAreaInset - self.bottomSafeAreaInset;
        _violinButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                                                 self.topSafeAreaInset + BUFFER,
                                                                 (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                 (availableHeight/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [_violinButton addGestureRecognizer:tapGesture];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(longPressed:)];
        [longPress setMinimumPressDuration:0.25f];
        [_violinButton addGestureRecognizer:longPress];
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
        CGFloat availableHeight = kScreenHeight - self.topSafeAreaInset - self.bottomSafeAreaInset;
        _frenchHornButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(BUFFER,
                                                               (availableHeight/2.0f) + self.topSafeAreaInset,
                                                               (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                               (availableHeight/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [_frenchHornButton addGestureRecognizer:tapGesture];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(longPressed:)];
        [longPress setMinimumPressDuration:0.25f];
        [_frenchHornButton addGestureRecognizer:longPress];
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
        CGFloat availableHeight = kScreenHeight - self.topSafeAreaInset - self.bottomSafeAreaInset;
        _sineWaveButton = [[A4InstrumentView alloc] initWithFrame:CGRectMake(kScreenWidth/2.0f + BUFFER,
                                                                   (availableHeight/2.0f) + self.topSafeAreaInset,
                                                                   (kScreenWidth/2.0f) * BUTTON_SCALE,
                                                                   (availableHeight/2.0f) * BUTTON_SCALE)];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [_sineWaveButton addGestureRecognizer:tapGesture];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(longPressed:)];
        [longPress setMinimumPressDuration:0.25f];
        [_sineWaveButton addGestureRecognizer:longPress];
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

- (void)longPressed:(UILongPressGestureRecognizer *)longPress {
    UIView *buttonView = [longPress view];
    
    if ([longPress state] == UIGestureRecognizerStateBegan || [longPress state] == UIGestureRecognizerStateEnded) {
        if (buttonView.tag == 1) {
            [self.audioPlayer stop];
            [self resetButtons];
        }
        
        else {
            NSString *audioFileName = @"";
            if ([buttonView isEqual:self.pianoButton]) {
                audioFileName = @"piano";
            }
            
            else if ([buttonView isEqual:self.violinButton]) {
                audioFileName = @"violin";
            }
            
            else if ([buttonView isEqual:self.frenchHornButton]) {
                audioFileName = @"frenchHorn";
            }
            
            else if ([buttonView isEqual:self.sineWaveButton]) {
                audioFileName = @"sineWave";
            }
            
            [self playAudioFile:audioFileName];
            [self resetButtons];
            [buttonView setTag:1];
        }
        
        [self animateButtons];
    }
}

- (void)tapped:(UITapGestureRecognizer *)tap {
    UIView *buttonView = [tap view];
    if (buttonView.tag == 1) {
        [self.audioPlayer stop];
        [self resetButtons];
    }
    
    else {
        NSString *audioFileName = @"";
        if ([buttonView isEqual:self.pianoButton]) {
            audioFileName = @"piano";
        }
        
        else if ([buttonView isEqual:self.violinButton]) {
            audioFileName = @"violin";
        }
        
        else if ([buttonView isEqual:self.frenchHornButton]) {
            audioFileName = @"frenchHorn";
        }
        
        else if ([buttonView isEqual:self.sineWaveButton]) {
            audioFileName = @"sineWave";
        }
        
        [self playAudioFile:audioFileName];
        [self resetButtons];
        [buttonView setTag:1];
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
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer stop];
    }
    
    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@.wav", [[NSBundle mainBundle] resourcePath], fileName];
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

#pragma mark - gradient

- (CAGradientLayer *)shadowGradient {
    NSArray *colors = [NSArray arrayWithObjects:
                       (id)[UIColor colorWithWhite:1.0f alpha:0.41f].CGColor,
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
