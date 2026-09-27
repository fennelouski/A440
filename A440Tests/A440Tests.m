//
//  A440Tests.m
//  A440Tests
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//
//  Unit tests for the A440 concert-pitch reference app. The suite is hosted
//  inside the app, so it exercises the real bundle, the real color system,
//  and the real instrument cards.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AVFoundation/AVFoundation.h>

#import "A4InstrumentView.h"
#import "UIColor+AppColors.h"
#import "AppDelegate.h"
#import "A440-Swift.h"

@interface A440Tests : XCTestCase
@end

@implementation A440Tests

#pragma mark - Audio assets

- (void)testAllInstrumentAudioFilesAreBundled {
    for (NSString *name in @[@"piano", @"violin", @"frenchHorn", @"sineWave"]) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:@"wav"];
        XCTAssertNotNil(url, @"%@.wav is missing from the app bundle", name);
    }
}

- (void)testBundledAudioFilesAreValidAndRoughlyOneSecondOrLonger {
    for (NSString *name in @[@"piano", @"violin", @"frenchHorn", @"sineWave"]) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:@"wav"];
        NSError *error = nil;
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        XCTAssertNotNil(player, @"%@.wav failed to load: %@", name, error);
        XCTAssertNil(error);
        XCTAssertGreaterThan(player.duration, 0.5, @"%@.wav is implausibly short", name);
    }
}

#pragma mark - Instrument cards

- (void)testInstrumentViewsMapInstrumentToAudioFileAndDisplayName {
    A4InstrumentView *piano = [[A4InstrumentView alloc] initWithInstrument:A4InstrumentPiano];
    A4InstrumentView *violin = [[A4InstrumentView alloc] initWithInstrument:A4InstrumentViolin];
    A4InstrumentView *horn = [[A4InstrumentView alloc] initWithInstrument:A4InstrumentFrenchHorn];
    A4InstrumentView *sine = [[A4InstrumentView alloc] initWithInstrument:A4InstrumentSineWave];

    XCTAssertEqualObjects(piano.audioFileName, @"piano");
    XCTAssertEqualObjects(violin.audioFileName, @"violin");
    XCTAssertEqualObjects(horn.audioFileName, @"frenchHorn");
    XCTAssertEqualObjects(sine.audioFileName, @"sineWave");

    XCTAssertEqualObjects(piano.displayName, @"Piano");
    XCTAssertEqualObjects(violin.displayName, @"Violin");
    XCTAssertEqualObjects(horn.displayName, @"French Horn");
    XCTAssertEqualObjects(sine.displayName, @"Sine Wave");
}

- (void)testEveryInstrumentAudioFileNameResolvesToABundledFile {
    for (NSNumber *value in @[@(A4InstrumentPiano), @(A4InstrumentViolin),
                              @(A4InstrumentFrenchHorn), @(A4InstrumentSineWave)]) {
        A4InstrumentView *view = [[A4InstrumentView alloc] initWithInstrument:value.integerValue];
        NSURL *url = [[NSBundle mainBundle] URLForResource:view.audioFileName withExtension:@"wav"];
        XCTAssertNotNil(url, @"Card '%@' points at a missing audio file '%@.wav'",
                        view.displayName, view.audioFileName);
    }
}

- (void)testPlayingStateTogglesAndSurvivesLegacyAppearanceSwap {
    A4InstrumentView *view = [[A4InstrumentView alloc] initWithInstrument:A4InstrumentViolin];
    view.frame = CGRectMake(0, 0, 160, 220);
    [view layoutIfNeeded];

    XCTAssertFalse(view.isPlaying);
    [view setPlaying:YES animated:NO];
    XCTAssertTrue(view.isPlaying);

    view.legacyAppearance = YES;
    [view layoutIfNeeded];
    XCTAssertTrue(view.isPlaying, @"Swapping designs must not silently clear the playing state");

    view.legacyAppearance = NO;
    [view setPlaying:NO animated:NO];
    XCTAssertFalse(view.isPlaying);
}

- (void)testRoundedFontHelperReturnsRequestedSize {
    UIFont *font = A4RoundedFont(17.0, UIFontWeightSemibold);
    XCTAssertNotNil(font);
    XCTAssertEqualWithAccuracy(font.pointSize, 17.0, 0.01);
}

#pragma mark - Color system

- (void)testAllAppColorsResolve {
    NSArray<UIColor *> *colors = @[
        UIColor.a4BackgroundTop, UIColor.a4BackgroundBottom, UIColor.a4Glow,
        UIColor.a4CardSurface, UIColor.a4CardBorder, UIColor.a4ShadowColor,
        UIColor.a4TextPrimary, UIColor.a4TextSecondary, UIColor.a4TextTertiary,
        UIColor.a4BrandTop, UIColor.a4BrandBottom,
        UIColor.a4AccentPiano, UIColor.a4AccentViolin,
        UIColor.a4AccentFrenchHorn, UIColor.a4AccentSine,
        UIColor.a4LegacyCard, UIColor.a4LegacyGradientTop,
        UIColor.a4LegacyGradientBottom, UIColor.a4LegacyNightBottom,
    ];
    for (UIColor *color in colors) {
        XCTAssertNotNil(color);
    }
}

- (void)testBackgroundColorAdaptsToDarkMode {
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];

    UIColor *lightResolved = [UIColor.a4BackgroundTop resolvedColorWithTraitCollection:light];
    UIColor *darkResolved = [UIColor.a4BackgroundTop resolvedColorWithTraitCollection:dark];
    XCTAssertFalse([lightResolved isEqual:darkResolved],
                   @"The background must resolve differently in light and dark mode");
}

- (void)testLegacyColorsAreFixedAcrossAppearances {
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];

    UIColor *lightResolved = [UIColor.a4LegacyCard resolvedColorWithTraitCollection:light];
    UIColor *darkResolved = [UIColor.a4LegacyCard resolvedColorWithTraitCollection:dark];
    XCTAssertEqualObjects(lightResolved, darkResolved,
                          @"The 2015 design predates Dark Mode and must not adapt");
}

- (void)testHexHelperProducesExpectedComponents {
    UIColor *color = [UIColor a4ColorWithLightHex:0xFF8040 darkHex:0x000000];
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [[color resolvedColorWithTraitCollection:light] getRed:&r green:&g blue:&b alpha:&a];
    XCTAssertEqualWithAccuracy(r, 0xFF / 255.0, 0.005);
    XCTAssertEqualWithAccuracy(g, 0x80 / 255.0, 0.005);
    XCTAssertEqualWithAccuracy(b, 0x40 / 255.0, 0.005);
    XCTAssertEqualWithAccuracy(a, 1.0, 0.001);
}

- (void)testDarkenedVariantIsActuallyDarker {
    UIColor *base = [UIColor colorWithRed:0.6 green:0.5 blue:0.4 alpha:1.0];
    UIColor *darker = [base a4Darkened:0.3];
    CGFloat br = 0, bg = 0, bb = 0, ba = 0, dr = 0, dg = 0, db = 0, da = 0;
    [base getRed:&br green:&bg blue:&bb alpha:&ba];
    [darker getRed:&dr green:&dg blue:&db alpha:&da];
    XCTAssertLessThan(dr, br);
    XCTAssertLessThan(dg, bg);
    XCTAssertLessThan(db, bb);
}

#pragma mark - App wiring

- (void)testWindowHasViewControllerAsRoot {
    UIApplication *app = UIApplication.sharedApplication;
    AppDelegate *delegate = (AppDelegate *)app.delegate;
    XCTAssertNotNil(delegate.window, @"AppDelegate must create the window programmatically");
    XCTAssertTrue([delegate.window.rootViewController isKindOfClass:[TunerViewController class]]);
}

- (void)testLastInstrumentDefaultIsSeededOnFirstLaunch {
    // viewDidLoad has run by the time tests execute, so the seed must exist.
    NSString *lastFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastFile"];
    XCTAssertNotNil(lastFile, @"The last-instrument default must be seeded at launch");
    NSArray *valid = @[@"piano", @"violin", @"frenchHorn", @"sineWave"];
    XCTAssertTrue([valid containsObject:lastFile], @"Unexpected instrument '%@'", lastFile);
}

- (void)testPlaybackSwitchStopAndInterruption {
    TonePlayer *audio = [[TonePlayer alloc] init];
    XCTAssertEqual(audio.activeInstrument, -1);
    for (NSInteger index = 0; index < 4; index++) {
        [audio toggle:index];
        XCTAssertEqual(audio.activeInstrument, index);
    }
    [audio toggle:3];
    XCTAssertEqual(audio.activeInstrument, -1);
    [audio toggle:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVAudioSessionInterruptionNotification
        object:nil userInfo:@{ AVAudioSessionInterruptionTypeKey: @(AVAudioSessionInterruptionTypeBegan) }];
    XCTAssertEqual(audio.activeInstrument, -1);
    [audio toggle:1];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    XCTAssertEqual(audio.activeInstrument, -1);
    [audio toggle:99];
    XCTAssertEqual(audio.activeInstrument, -1);
}

@end
