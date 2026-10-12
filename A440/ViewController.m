//
//  ViewController.m
//  A440
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "ViewController.h"
#import "UIColor+AppColors.h"
#import "A4InstrumentView.h"

static NSString * const kLastFileKey = @"lastFile";
static NSString * const kLegacyDesignKey = @"legacyDesign";
static const NSTimeInterval kStateAnimationDuration = 0.28;
static const NSTimeInterval kDesignSwapDuration = 0.45;

@interface ViewController ()

@property (nonatomic, strong) CAGradientLayer *backgroundLayer;
@property (nonatomic, strong) CAGradientLayer *glowLayer;

@property (nonatomic, strong) UIView *brandMark;
@property (nonatomic, strong) CAGradientLayer *brandGradient;
@property (nonatomic, strong) CAShapeLayer *tuningForkLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *nowPlayingCaption;
@property (nonatomic, strong) UILabel *nowPlayingValue;
@property (nonatomic, strong) UILabel *footerLabel;

@property (nonatomic, strong) NSArray<A4InstrumentView *> *instrumentViews;
@property (nonatomic, weak) A4InstrumentView *activeInstrumentView;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) UIImpactFeedbackGenerator *feedbackGenerator;

/// Shake toggles between this redesign and the original 2015 appearance.
@property (nonatomic, assign, getter=isLegacyDesign) BOOL legacyDesign;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureAudioSession];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kLastFileKey]) {
        [defaults setObject:@"sineWave" forKey:kLastFileKey];
    }

    [self setUpBackground];
    [self setUpHeader];
    [self setUpInstrumentViews];
    [self setUpFooter];

    self.feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

    if ([defaults boolForKey:kLegacyDesignKey]) {
        [self setLegacyDesign:YES animated:NO];
    }

    // Stop cleanly when another app or a call takes over the audio session.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAudioInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Setup

- (void)setUpBackground {
    self.backgroundLayer = [CAGradientLayer layer];
    self.backgroundLayer.startPoint = CGPointMake(0.5f, 0.0f);
    self.backgroundLayer.endPoint = CGPointMake(0.5f, 1.0f);
    [self.view.layer insertSublayer:self.backgroundLayer atIndex:0];

    self.glowLayer = [CAGradientLayer layer];
    self.glowLayer.type = kCAGradientLayerRadial;
    self.glowLayer.startPoint = CGPointMake(0.5f, 0.0f);
    self.glowLayer.endPoint = CGPointMake(1.15f, 0.6f);
    [self.view.layer insertSublayer:self.glowLayer above:self.backgroundLayer];
}

- (void)setUpHeader {
    self.brandMark = [[UIView alloc] init];
    self.brandMark.layer.cornerCurve = kCACornerCurveContinuous;
    self.brandMark.layer.masksToBounds = YES;
    [self.view addSubview:self.brandMark];

    self.brandGradient = [CAGradientLayer layer];
    self.brandGradient.startPoint = CGPointMake(0.1f, 0.0f);
    self.brandGradient.endPoint = CGPointMake(0.9f, 1.0f);
    self.brandGradient.colors = @[(id)[UIColor a4BrandTop].CGColor,
                                  (id)[UIColor a4BrandBottom].CGColor];
    [self.brandMark.layer addSublayer:self.brandGradient];

    self.tuningForkLayer = [CAShapeLayer layer];
    self.tuningForkLayer.fillColor = NULL;
    self.tuningForkLayer.strokeColor = [UIColor colorWithWhite:1.0f alpha:0.96f].CGColor;
    self.tuningForkLayer.lineCap = kCALineCapRound;
    self.tuningForkLayer.lineJoin = kCALineJoinRound;
    [self.brandMark.layer addSublayer:self.tuningForkLayer];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"A440";
    self.titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;
    [self.view addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"Concert pitch reference";
    [self.view addSubview:self.subtitleLabel];

    self.nowPlayingCaption = [[UILabel alloc] init];
    self.nowPlayingCaption.textAlignment = NSTextAlignmentRight;
    self.nowPlayingCaption.attributedText =
        [[NSAttributedString alloc] initWithString:@"TUNING"
                                        attributes:@{NSKernAttributeName: @(1.1f)}];
    self.nowPlayingCaption.isAccessibilityElement = NO;
    [self.view addSubview:self.nowPlayingCaption];

    self.nowPlayingValue = [[UILabel alloc] init];
    self.nowPlayingValue.textAlignment = NSTextAlignmentRight;
    self.nowPlayingValue.text = @"440 Hz";
    [self.view addSubview:self.nowPlayingValue];
}

- (void)setUpInstrumentViews {
    NSArray<NSNumber *> *instruments = @[@(A4InstrumentPiano),
                                         @(A4InstrumentViolin),
                                         @(A4InstrumentFrenchHorn),
                                         @(A4InstrumentSineWave)];
    NSMutableArray<A4InstrumentView *> *views = [NSMutableArray arrayWithCapacity:instruments.count];

    for (NSNumber *raw in instruments) {
        A4InstrumentView *view = [[A4InstrumentView alloc] initWithInstrument:(A4Instrument)raw.integerValue];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        [view addGestureRecognizer:tap];

        UILongPressGestureRecognizer *longPress =
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        longPress.minimumPressDuration = 0.25f;
        [view addGestureRecognizer:longPress];

        view.isAccessibilityElement = YES;
        view.accessibilityLabel = view.displayName;
        view.accessibilityHint = [NSString stringWithFormat:
                                  @"Tap to play the A440 %@ tone, tap again to stop. Long press to stop playback.",
                                  view.displayName.lowercaseString];
        view.accessibilityTraits = UIAccessibilityTraitButton;

        [self.view addSubview:view];
        [views addObject:view];
    }

    self.instrumentViews = [views copy];
}

- (void)setUpFooter {
    self.footerLabel = [[UILabel alloc] init];
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    self.footerLabel.numberOfLines = 0;
    self.footerLabel.text = @"440 Hz concert A · tap to play, tap again to stop\nShake to compare with the 2015 design";
    self.footerLabel.isAccessibilityElement = NO;
    [self.view addSubview:self.footerLabel];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect bounds = self.view.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    if (width <= 0.0f || height <= 0.0f) return;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.backgroundLayer.frame = bounds;
    self.glowLayer.frame = bounds;
    [CATransaction commit];

    UIEdgeInsets safe = self.view.safeAreaInsets;

    if (self.isLegacyDesign) {
        [self layoutLegacyGridInBounds:bounds safeArea:safe];
        return;
    }

    CGFloat scale = MIN(1.4f, MAX(1.0f, width / 390.0f));
    CGFloat margin = MAX(16.0f, MIN(34.0f, width * 0.055f));
    CGFloat gap = MAX(10.0f, MIN(20.0f, width * 0.032f));

    // Header
    CGFloat markSide = round(34.0f * scale);
    CGFloat headerTop = safe.top + (10.0f * scale);
    self.brandMark.frame = CGRectMake(margin, headerTop, markSide, markSide);
    self.brandMark.layer.cornerRadius = markSide * 0.3f;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.brandGradient.frame = self.brandMark.bounds;
    self.tuningForkLayer.frame = self.brandMark.bounds;
    self.tuningForkLayer.lineWidth = 8.0f * (markSide / 100.0f);
    UIBezierPath *fork = [self tuningForkPath];
    [fork applyTransform:CGAffineTransformMakeScale(markSide / 100.0f, markSide / 100.0f)];
    self.tuningForkLayer.path = fork.CGPath;
    [CATransaction commit];

    self.titleLabel.font = A4RoundedFont(round(24.0f * scale), UIFontWeightBold);
    self.subtitleLabel.font = A4RoundedFont(round(12.0f * scale), UIFontWeightMedium);
    self.nowPlayingCaption.font = A4RoundedFont(round(9.0f * scale), UIFontWeightBold);
    self.nowPlayingValue.font = A4RoundedFont(round(14.0f * scale), UIFontWeightSemibold);
    self.footerLabel.font = A4RoundedFont(round(11.0f * scale), UIFontWeightMedium);

    CGFloat textLeft = CGRectGetMaxX(self.brandMark.frame) + (10.0f * scale);
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGSize subtitleSize = [self.subtitleLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    self.titleLabel.frame = CGRectMake(textLeft, headerTop - 2.0f, titleSize.width, titleSize.height);
    self.subtitleLabel.frame = CGRectMake(textLeft,
                                          CGRectGetMaxY(self.titleLabel.frame) + 1.0f,
                                          subtitleSize.width,
                                          subtitleSize.height);

    CGSize captionSize = [self.nowPlayingCaption sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGSize valueSize = [self.nowPlayingValue sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat rightEdge = width - margin;
    CGFloat statusWidth = MAX(captionSize.width, MAX(valueSize.width, 90.0f * scale));
    self.nowPlayingCaption.frame = CGRectMake(rightEdge - statusWidth, headerTop + 1.0f, statusWidth, captionSize.height);
    self.nowPlayingValue.frame = CGRectMake(rightEdge - statusWidth,
                                            CGRectGetMaxY(self.nowPlayingCaption.frame) + 2.0f,
                                            statusWidth,
                                            valueSize.height);

    // Footer
    CGSize footerSize = [self.footerLabel sizeThatFits:CGSizeMake(width - (margin * 2.0f), CGFLOAT_MAX)];
    CGFloat footerY = height - safe.bottom - (8.0f * scale) - footerSize.height;
    self.footerLabel.frame = CGRectMake(margin, footerY, width - (margin * 2.0f), footerSize.height);

    // 2x2 instrument grid
    CGFloat headerBottom = MAX(CGRectGetMaxY(self.brandMark.frame),
                               MAX(CGRectGetMaxY(self.subtitleLabel.frame),
                                   CGRectGetMaxY(self.nowPlayingValue.frame)));
    CGFloat gridTop = headerBottom + (14.0f * scale);
    CGFloat gridBottom = footerY - (10.0f * scale);
    CGFloat gridWidth = width - (margin * 2.0f);
    CGFloat gridHeight = MAX(0.0f, gridBottom - gridTop);

    CGFloat cellWidth = floor((gridWidth - gap) / 2.0f);
    CGFloat cellHeight = floor((gridHeight - gap) / 2.0f);

    for (NSUInteger index = 0; index < self.instrumentViews.count; index++) {
        NSUInteger row = index / 2;
        NSUInteger column = index % 2;
        CGRect frame = CGRectMake(margin + (column * (cellWidth + gap)),
                                  gridTop + (row * (cellHeight + gap)),
                                  cellWidth,
                                  cellHeight);
        self.instrumentViews[index].frame = frame;
    }
}

/// Reproduces the original frame maths: 5% buffer, 0.8 scale, then a 0.98 nudge.
- (void)layoutLegacyGridInBounds:(CGRect)bounds safeArea:(UIEdgeInsets)safe {
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat availableHeight = height - safe.top - safe.bottom;
    CGFloat buffer = width * 0.05f;
    CGFloat cellWidth = (width / 2.0f) * 0.8f;
    CGFloat cellHeight = (availableHeight / 2.0f) * 0.8f;
    CGFloat secondRowY = (availableHeight / 2.0f) + safe.top + 20.0f;

    CGRect frames[4] = {
        CGRectMake(buffer, safe.top + buffer, cellWidth, cellHeight),
        CGRectMake((width / 2.0f) + buffer, safe.top + buffer, cellWidth, cellHeight),
        CGRectMake(buffer, secondRowY, cellWidth, cellHeight),
        CGRectMake((width / 2.0f) + buffer, secondRowY, cellWidth, cellHeight)
    };

    for (NSUInteger index = 0; index < self.instrumentViews.count && index < 4; index++) {
        CGRect frame = frames[index];
        CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        frame.size.width *= 0.98f;
        frame.size.height *= 0.98f;
        frame.origin.x = center.x - (frame.size.width / 2.0f);
        frame.origin.y = center.y - (frame.size.height / 2.0f);
        self.instrumentViews[index].frame = frame;
    }
}

- (UIBezierPath *)tuningForkPath {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(35.0f, 20.0f)];
    [path addLineToPoint:CGPointMake(35.0f, 50.0f)];
    [path addQuadCurveToPoint:CGPointMake(50.0f, 63.0f) controlPoint:CGPointMake(35.0f, 63.0f)];
    [path addQuadCurveToPoint:CGPointMake(65.0f, 50.0f) controlPoint:CGPointMake(65.0f, 63.0f)];
    [path addLineToPoint:CGPointMake(65.0f, 20.0f)];
    [path moveToPoint:CGPointMake(50.0f, 63.0f)];
    [path addLineToPoint:CGPointMake(50.0f, 84.0f)];
    return path;
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyAppearanceColors];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self applyAppearanceColors];
        for (A4InstrumentView *view in self.instrumentViews) {
            [view updateForCurrentTraits];
        }
    }
}

- (void)applyAppearanceColors {
    UITraitCollection *traits = self.traitCollection;
    UIColor *glow = [[UIColor a4Glow] resolvedColorWithTraitCollection:traits];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.isLegacyDesign) {
        self.backgroundLayer.colors = self.isNightTime
            ? @[(id)[UIColor a4LegacyGradientBottom].CGColor, (id)[UIColor a4LegacyNightBottom].CGColor]
            : @[(id)[UIColor a4LegacyGradientTop].CGColor, (id)[UIColor a4LegacyGradientBottom].CGColor];
        self.backgroundLayer.locations = @[@0.3f, @1.0f];
        self.glowLayer.opacity = 0.0f;
    } else {
        self.backgroundLayer.colors = @[(id)[[UIColor a4BackgroundTop] resolvedColorWithTraitCollection:traits].CGColor,
                                        (id)[[UIColor a4BackgroundBottom] resolvedColorWithTraitCollection:traits].CGColor];
        self.backgroundLayer.locations = nil;
        self.glowLayer.colors = @[(id)glow.CGColor,
                                  (id)[glow colorWithAlphaComponent:0.0f].CGColor];
        self.glowLayer.opacity = 1.0f;
    }
    [CATransaction commit];

    self.titleLabel.textColor = [UIColor a4TextPrimary];
    self.subtitleLabel.textColor = [UIColor a4TextSecondary];
    self.nowPlayingCaption.textColor = [UIColor a4TextTertiary];
    self.footerLabel.textColor = [UIColor a4TextTertiary];
    [self updateNowPlayingLabel];
}

- (void)updateNowPlayingLabel {
    A4InstrumentView *active = self.activeInstrumentView;

    if (active) {
        self.nowPlayingValue.text = active.displayName;
        self.nowPlayingValue.textColor = active.accentColor;
    } else {
        self.nowPlayingValue.text = @"440 Hz";
        self.nowPlayingValue.textColor = [UIColor a4TextPrimary];
    }
}

#pragma mark - Shake to compare designs

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];   // required to receive motion events
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [self.feedbackGenerator prepare];
        [self setLegacyDesign:!self.isLegacyDesign animated:YES];
        [self.feedbackGenerator impactOccurred];
        return;
    }

    [super motionEnded:motion withEvent:event];
}

- (void)setLegacyDesign:(BOOL)legacyDesign animated:(BOOL)animated {
    if (_legacyDesign == legacyDesign) return;
    _legacyDesign = legacyDesign;

    [[NSUserDefaults standardUserDefaults] setBool:legacyDesign forKey:kLegacyDesignKey];

    void (^apply)(void) = ^{
        // The 2015 design had no chrome: just four buttons on a green gradient.
        self.brandMark.hidden = legacyDesign;
        self.titleLabel.hidden = legacyDesign;
        self.subtitleLabel.hidden = legacyDesign;
        self.nowPlayingCaption.hidden = legacyDesign;
        self.nowPlayingValue.hidden = legacyDesign;
        self.footerLabel.hidden = legacyDesign;

        for (A4InstrumentView *view in self.instrumentViews) {
            view.legacyAppearance = legacyDesign;
        }

        [self applyAppearanceColors];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    };

    if (animated) {
        [UIView transitionWithView:self.view
                          duration:kDesignSwapDuration
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:apply
                        completion:nil];
    } else {
        apply();
    }

    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    legacyDesign ? @"Original 2015 design" : @"Current design");
}

/// The original background swapped to a darker gradient late at night.
- (BOOL)isNightTime {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour
                                                                   fromDate:[NSDate date]];
    NSInteger hour = components.hour;
    return (hour < 6 || hour > 22);
}

#pragma mark - Audio Session

- (void)configureAudioSession {
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    // Playback category so the reference tone sounds even with the silent switch on.
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback
                                        mode:AVAudioSessionModeDefault
                                     options:0
                                       error:&error];
    if (!success || error) {
        NSLog(@"Error setting audio session category: %@", error.localizedDescription);
    }

    success = [audioSession setActive:YES error:&error];
    if (!success || error) {
        NSLog(@"Error activating audio session: %@", error.localizedDescription);
    }
}

- (void)handleAudioInterruption:(NSNotification *)notification {
    NSNumber *interruptionType = notification.userInfo[AVAudioSessionInterruptionTypeKey];

    if (interruptionType.unsignedIntegerValue == AVAudioSessionInterruptionTypeBegan) {
        if ([self.audioPlayer isPlaying]) {
            [self.audioPlayer stop];
            [self setActiveInstrumentView:nil animated:YES];
        }
    } else if (interruptionType.unsignedIntegerValue == AVAudioSessionInterruptionTypeEnded) {
        // Playback is not resumed automatically; the listener taps again.
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (error) {
            NSLog(@"Error reactivating audio session: %@", error.localizedDescription);
        }
    }
}

#pragma mark - Audio Player

- (AVAudioPlayer *)audioPlayer {
    if (!_audioPlayer) {
        NSString *lastFile = [[NSUserDefaults standardUserDefaults] objectForKey:kLastFileKey];
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@.wav",
                                   [[NSBundle mainBundle] resourcePath], lastFile];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];

        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
    }

    return _audioPlayer;
}

- (void)playAudioFile:(NSString *)fileName {
    if ([self.audioPlayer isPlaying]) {
        [self.audioPlayer stop];
    }

    NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@.wav",
                               [[NSBundle mainBundle] resourcePath], fileName];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];

    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];

    if (error) {
        NSLog(@"Error loading audio file %@: %@", fileName, error.localizedDescription);
        return;
    }

    [self.audioPlayer prepareToPlay];
    self.audioPlayer.numberOfLoops = -1; // Sustain the reference tone until stopped.
    self.audioPlayer.volume = 1.0f;

    [[NSUserDefaults standardUserDefaults] setObject:fileName forKey:kLastFileKey];

    BOOL success = [self.audioPlayer play];
    if (!success) {
        NSLog(@"Failed to start audio playback for %@", fileName);
    }
}

#pragma mark - Interaction

- (void)tapped:(UITapGestureRecognizer *)tap {
    [self toggleInstrumentView:(A4InstrumentView *)tap.view];
}

- (void)longPressed:(UILongPressGestureRecognizer *)longPress {
    // Matches the original behaviour: the tone sounds while held and stops on release.
    if (longPress.state == UIGestureRecognizerStateBegan ||
        longPress.state == UIGestureRecognizerStateEnded) {
        [self toggleInstrumentView:(A4InstrumentView *)longPress.view];
    }
}

- (void)toggleInstrumentView:(A4InstrumentView *)instrumentView {
    if (![instrumentView isKindOfClass:[A4InstrumentView class]]) return;

    [self.feedbackGenerator prepare];

    if (instrumentView == self.activeInstrumentView) {
        [self.audioPlayer stop];
        [self setActiveInstrumentView:nil animated:YES];
    } else {
        [self playAudioFile:instrumentView.audioFileName];
        [self setActiveInstrumentView:instrumentView animated:YES];
    }

    [self.feedbackGenerator impactOccurred];
}

- (void)setActiveInstrumentView:(A4InstrumentView *)activeInstrumentView animated:(BOOL)animated {
    _activeInstrumentView = activeInstrumentView;

    for (A4InstrumentView *view in self.instrumentViews) {
        BOOL isActive = (view == activeInstrumentView);
        [view setPlaying:isActive animated:animated];
        [view setDimmed:(activeInstrumentView != nil && !isActive) animated:animated];
    }

    if (animated) {
        [UIView transitionWithView:self.nowPlayingValue
                          duration:kStateAnimationDuration
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ [self updateNowPlayingLabel]; }
                        completion:nil];
    } else {
        [self updateNowPlayingLabel];
    }

    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    activeInstrumentView ? [NSString stringWithFormat:@"Playing %@", activeInstrumentView.displayName]
                                                         : @"Stopped");
}

@end
