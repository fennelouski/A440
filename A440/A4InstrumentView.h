//
//  A4InstrumentView.h
//  A440
//
//  Created by Developer Nathan on 3/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//
//  A tappable instrument card. Draws its own vector instrument glyph,
//  its name, and the reference pitch, and carries a clear playing state.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, A4Instrument) {
    A4InstrumentPiano,
    A4InstrumentViolin,
    A4InstrumentFrenchHorn,
    A4InstrumentSineWave
};

/// SF Pro Rounded at the given size/weight, falling back to the system face.
UIFont *A4RoundedFont(CGFloat size, UIFontWeight weight);

@interface A4InstrumentView : UIView

@property (nonatomic, readonly) A4Instrument instrument;
/// Base name of the bundled audio file, e.g. @"frenchHorn".
@property (nonatomic, readonly) NSString *audioFileName;
/// Display name, e.g. @"French Horn".
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, strong) UIColor *accentColor;
@property (nonatomic, assign, getter=isPlaying) BOOL playing;
/// Renders the original 2015 appearance: sage card plus the instrument photograph.
@property (nonatomic, assign, getter=isLegacyAppearance) BOOL legacyAppearance;

- (instancetype)initWithInstrument:(A4Instrument)instrument NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (void)setPlaying:(BOOL)playing animated:(BOOL)animated;
/// Fades the card back while a different instrument is sounding.
- (void)setDimmed:(BOOL)dimmed animated:(BOOL)animated;
/// Re-resolves dynamic colors after a light/dark appearance change.
- (void)updateForCurrentTraits;

@end

NS_ASSUME_NONNULL_END
