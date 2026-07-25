//
//  A4InstrumentView.m
//  A440
//
//  Created by Developer Nathan on 3/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "A4InstrumentView.h"
#import "UIColor+AppColors.h"

/// All glyphs are drawn on a 100x100 canvas and scaled to fit the card.
static const CGFloat kGlyphCanvas = 100.0f;
static const CGFloat kGlyphStroke = 4.8f;
static const CGFloat kSinePhaseSteps = 24.0f;

/// The legacy piano photograph's filename contains "ê". The build system copies it
/// in decomposed (NFD) form while a source literal is composed (NFC), so a plain
/// imageNamed: can miss it. Try both normalisations.
static UIImage *A4LegacyImageNamed(NSString *name) {
    UIImage *image = [UIImage imageNamed:name];
    if (!image) {
        image = [UIImage imageNamed:[name decomposedStringWithCanonicalMapping]];
    }
    if (!image) {
        image = [UIImage imageNamed:[name precomposedStringWithCanonicalMapping]];
    }
    return image;
}

UIFont *A4RoundedFont(CGFloat size, UIFontWeight weight) {
    UIFont *base = [UIFont systemFontOfSize:size weight:weight];
    UIFontDescriptor *rounded = [base.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    return rounded ? [UIFont fontWithDescriptor:rounded size:size] : base;
}

@interface A4InstrumentView ()

@property (nonatomic, assign) A4Instrument instrument;
@property (nonatomic, strong) CAGradientLayer *accentFillLayer;
@property (nonatomic, strong) CAShapeLayer *glyphStrokeLayer;
@property (nonatomic, strong) CAShapeLayer *glyphFillLayer;
@property (nonatomic, strong) CAShapeLayer *glyphPressedLayer;  // piano: the held A key
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *pitchLabel;
@property (nonatomic, strong) UIView *iconContainer;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) CGFloat glyphScale;

@property (nonatomic, strong) CAShapeLayer *hornCoilLayer;    // buzzes while sounding
@property (nonatomic, strong) CAShapeLayer *violinBowLayer;   // draws across the strings

// Built lazily, only if the listener shakes into the legacy design.
@property (nonatomic, strong) UIImageView *legacyImageView;
@property (nonatomic, strong) CAGradientLayer *legacyOverlayLayer;

@end

@implementation A4InstrumentView

#pragma mark - Lifecycle

- (instancetype)initWithInstrument:(A4Instrument)instrument {
    self = [super initWithFrame:CGRectZero];

    if (self) {
        _instrument = instrument;
        _accentColor = [[self class] defaultAccentForInstrument:instrument];
        _playing = NO;
        _glyphScale = 0.0f;

        self.backgroundColor = [UIColor a4CardSurface];
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.layer.borderWidth = 1.0f;
        self.layer.masksToBounds = NO;
        self.layer.shadowOffset = CGSizeMake(0.0f, 10.0f);
        self.layer.shadowRadius = 18.0f;
        self.layer.shadowOpacity = 1.0f;

        _accentFillLayer = [CAGradientLayer layer];
        _accentFillLayer.opacity = 0.0f;
        _accentFillLayer.startPoint = CGPointMake(0.15f, 0.0f);
        _accentFillLayer.endPoint = CGPointMake(0.85f, 1.0f);
        _accentFillLayer.cornerCurve = kCACornerCurveContinuous;
        [self.layer addSublayer:_accentFillLayer];

        _glyphFillLayer = [CAShapeLayer layer];
        _glyphFillLayer.strokeColor = NULL;
        [self.layer addSublayer:_glyphFillLayer];

        _glyphPressedLayer = [CAShapeLayer layer];
        _glyphPressedLayer.strokeColor = NULL;
        _glyphPressedLayer.opacity = 0.0f;
        [self.layer addSublayer:_glyphPressedLayer];

        _glyphStrokeLayer = [CAShapeLayer layer];
        _glyphStrokeLayer.fillColor = NULL;
        _glyphStrokeLayer.lineCap = kCALineCapRound;
        _glyphStrokeLayer.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_glyphStrokeLayer];

        // The horn's coil is its own layer so it can vibrate independently of the bell.
        _hornCoilLayer = [CAShapeLayer layer];
        _hornCoilLayer.fillColor = NULL;
        _hornCoilLayer.lineCap = kCALineCapRound;
        _hornCoilLayer.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_hornCoilLayer];

        _violinBowLayer = [CAShapeLayer layer];
        _violinBowLayer.fillColor = NULL;
        _violinBowLayer.lineCap = kCALineCapRound;
        _violinBowLayer.opacity = 0.0f;
        [self.layer addSublayer:_violinBowLayer];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = self.displayName;
        _titleLabel.numberOfLines = 2;
        [self addSubview:_titleLabel];

        _pitchLabel = [[UILabel alloc] init];
        _pitchLabel.text = @"440 Hz";
        [self addSubview:_pitchLabel];

        _iconContainer = [[UIView alloc] init];
        _iconContainer.userInteractionEnabled = NO;
        [self addSubview:_iconContainer];

        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        [_iconContainer addSubview:_iconView];

        [self updateForCurrentTraits];
    }

    return self;
}

#pragma mark - Instrument metadata

+ (UIColor *)defaultAccentForInstrument:(A4Instrument)instrument {
    switch (instrument) {
        case A4InstrumentPiano:      return [UIColor a4AccentPiano];
        case A4InstrumentViolin:     return [UIColor a4AccentViolin];
        case A4InstrumentFrenchHorn: return [UIColor a4AccentFrenchHorn];
        case A4InstrumentSineWave:   return [UIColor a4AccentSine];
    }
    return [UIColor a4AccentSine];
}

- (NSString *)audioFileName {
    switch (self.instrument) {
        case A4InstrumentPiano:      return @"piano";
        case A4InstrumentViolin:     return @"violin";
        case A4InstrumentFrenchHorn: return @"frenchHorn";
        case A4InstrumentSineWave:   return @"sineWave";
    }
    return @"sineWave";
}

/// Photograph used by the original 2015 design.
- (NSString *)legacyImageName {
    switch (self.instrument) {
        case A4InstrumentPiano:      return @"Piano_de_Cauda_de_Manuel_Inocêncio_Liberato_dos_Santos";
        case A4InstrumentViolin:     return @"Violin_Geige";
        case A4InstrumentFrenchHorn: return @"FrenchHorn";
        case A4InstrumentSineWave:   return @"Sine Wave Image";
    }
    return @"Sine Wave Image";
}

- (NSString *)displayName {
    switch (self.instrument) {
        case A4InstrumentPiano:      return @"Piano";
        case A4InstrumentViolin:     return @"Violin";
        case A4InstrumentFrenchHorn: return @"French Horn";
        case A4InstrumentSineWave:   return @"Sine Wave";
    }
    return @"";
}

#pragma mark - Layout

#pragma mark - Legacy appearance

- (void)setLegacyAppearance:(BOOL)legacyAppearance {
    if (_legacyAppearance == legacyAppearance) return;
    _legacyAppearance = legacyAppearance;

    if (legacyAppearance && !self.legacyImageView) {
        [self buildLegacyLayers];
    }

    self.titleLabel.hidden = legacyAppearance;
    self.pitchLabel.hidden = legacyAppearance;
    self.iconContainer.hidden = legacyAppearance;
    self.glyphStrokeLayer.hidden = legacyAppearance;
    self.glyphFillLayer.hidden = legacyAppearance;
    self.glyphPressedLayer.hidden = legacyAppearance;
    self.accentFillLayer.hidden = legacyAppearance;

    self.legacyImageView.hidden = !legacyAppearance;
    self.legacyOverlayLayer.hidden = !legacyAppearance;

    [self updateForCurrentTraits];
    [self setNeedsLayout];
}

- (void)buildLegacyLayers {
    // The original card's specular overlay, flipped end-over-end while sounding.
    _legacyOverlayLayer = [CAGradientLayer layer];
    _legacyOverlayLayer.colors = @[(id)[UIColor colorWithWhite:1.0f alpha:0.41f].CGColor,
                                   (id)[UIColor colorWithWhite:0.9f alpha:0.0f].CGColor,
                                   (id)[UIColor clearColor].CGColor,
                                   (id)[UIColor colorWithWhite:0.0f alpha:0.2f].CGColor];
    _legacyOverlayLayer.locations = @[@0.0f, @0.15f, @0.75f, @1.0f];
    [self.layer addSublayer:_legacyOverlayLayer];

    _legacyImageView = [[UIImageView alloc] initWithImage:A4LegacyImageNamed([self legacyImageName])];
    _legacyImageView.contentMode = UIViewContentModeScaleAspectFit;
    _legacyImageView.userInteractionEnabled = NO;
    [self addSubview:_legacyImageView];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    if (w <= 0.0f || h <= 0.0f) return;

    if (self.legacyAppearance) {
        CGFloat legacyRadius = h / 8.0f;   // original CORNER_RADIUS_RATIO
        self.layer.cornerCurve = kCACornerCurveCircular;
        self.layer.cornerRadius = legacyRadius;
        self.layer.shadowOffset = CGSizeMake(-5.0f, 8.0f);
        self.layer.shadowRadius = 8.0f;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                           cornerRadius:legacyRadius].CGPath;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.legacyOverlayLayer.frame = self.bounds;
        self.legacyOverlayLayer.cornerRadius = legacyRadius;
        [CATransaction commit];
        self.legacyImageView.frame = self.bounds;
        return;
    }

    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.layer.shadowOffset = CGSizeMake(0.0f, 10.0f);
    self.layer.shadowRadius = 18.0f;

    CGFloat radius = MAX(18.0f, MIN(30.0f, MIN(w, h) * 0.17f));
    self.layer.cornerRadius = radius;
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius].CGPath;

    self.accentFillLayer.frame = self.bounds;
    self.accentFillLayer.cornerRadius = radius;

    CGFloat pad = MAX(12.0f, MIN(22.0f, w * 0.11f));
    CGFloat iconSide = MAX(26.0f, MIN(34.0f, w * 0.19f));

    self.titleLabel.font = A4RoundedFont(MAX(14.0f, MIN(22.0f, w * 0.115f)), UIFontWeightBold);
    self.pitchLabel.font = A4RoundedFont(MAX(10.0f, MIN(14.0f, w * 0.072f)), UIFontWeightSemibold);

    CGFloat labelWidth = MAX(0.0f, w - (pad * 2.0f) - iconSide - 6.0f);
    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    CGSize pitchSize = [self.pitchLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];

    CGFloat bottom = h - pad;
    self.pitchLabel.frame = CGRectMake(pad, bottom - pitchSize.height, labelWidth, pitchSize.height);
    self.titleLabel.frame = CGRectMake(pad,
                                       CGRectGetMinY(self.pitchLabel.frame) - titleSize.height - 1.0f,
                                       labelWidth,
                                       titleSize.height);

    self.iconContainer.frame = CGRectMake(w - pad - iconSide, bottom - iconSide, iconSide, iconSide);
    self.iconContainer.layer.cornerRadius = iconSide / 2.0f;
    CGFloat inset = iconSide * 0.29f;
    self.iconView.frame = CGRectInset(self.iconContainer.bounds, inset, inset);

    // Glyph fills the space between the top padding and the labels.
    CGFloat glyphTop = pad;
    CGFloat glyphBottom = CGRectGetMinY(self.titleLabel.frame) - 6.0f;
    CGFloat available = MAX(0.0f, glyphBottom - glyphTop);
    CGFloat side = MAX(0.0f, MIN(available, w - (pad * 2.0f)));

    CGRect glyphRect = CGRectMake(round((w - side) / 2.0f),
                                  round(glyphTop + ((available - side) / 2.0f)),
                                  side,
                                  side);

    self.glyphScale = side / kGlyphCanvas;
    for (CAShapeLayer *layer in @[self.glyphStrokeLayer, self.glyphFillLayer,
                                  self.glyphPressedLayer, self.violinBowLayer]) {
        layer.frame = glyphRect;
    }

    // Anchor the coil on its own centre (38,62 of the canvas) so the buzz rotates in place.
    self.hornCoilLayer.bounds = CGRectMake(0.0f, 0.0f, side, side);
    self.hornCoilLayer.anchorPoint = CGPointMake(0.38f, 0.62f);
    self.hornCoilLayer.position = CGPointMake(CGRectGetMinX(glyphRect) + (side * 0.38f),
                                              CGRectGetMinY(glyphRect) + (side * 0.62f));

    self.glyphStrokeLayer.lineWidth = kGlyphStroke * self.glyphScale;
    self.hornCoilLayer.lineWidth = kGlyphStroke * self.glyphScale;
    self.violinBowLayer.lineWidth = kGlyphStroke * self.glyphScale * 0.85f;

    [self rebuildGlyphPaths];
}

- (void)rebuildGlyphPaths {
    if (self.glyphScale <= 0.0f) {
        // No room to draw (e.g. a very short landscape card) - clear rather than
        // leaving a stale path from the previous layout.
        self.glyphStrokeLayer.path = NULL;
        self.glyphFillLayer.path = NULL;
        self.glyphPressedLayer.path = NULL;
        self.hornCoilLayer.path = NULL;
        self.violinBowLayer.path = NULL;
        return;
    }

    CGAffineTransform scale = CGAffineTransformMakeScale(self.glyphScale, self.glyphScale);

    UIBezierPath *stroke = [self strokePath];
    [stroke applyTransform:scale];
    self.glyphStrokeLayer.path = stroke.CGPath;

    UIBezierPath *fill = [self fillPath];
    [fill applyTransform:scale];
    self.glyphFillLayer.path = fill.CGPath;

    UIBezierPath *pressed = [self pressedPath];
    [pressed applyTransform:scale];
    self.glyphPressedLayer.path = pressed.CGPath;

    UIBezierPath *coil = [self hornCoilPath];
    [coil applyTransform:scale];
    self.hornCoilLayer.path = coil.CGPath;

    UIBezierPath *bow = [self violinBowPath];
    [bow applyTransform:scale];
    self.violinBowLayer.path = bow.CGPath;

    if (self.playing) {
        [self startPlayingAnimations];
    }
}

#pragma mark - Glyph paths (100x100 canvas)

/// The horn's coiled tubing: a true Archimedean spiral, so it reads as wrapped
/// tubing rather than a plain ring. Separate from the bell so it can vibrate.
- (UIBezierPath *)hornCoilPath {
    UIBezierPath *p = [UIBezierPath bezierPath];
    if (self.instrument != A4InstrumentFrenchHorn) return p;

    const CGPoint center = CGPointMake(38.0f, 62.0f);
    const CGFloat innerRadius = 8.0f, outerRadius = 21.0f;
    const CGFloat sweep = 2.35f * 2.0f * (CGFloat)M_PI;
    const CGFloat start = (CGFloat)(-M_PI_2) - sweep;   // exits at the top, heading right
    const NSInteger steps = 170;

    for (NSInteger i = 0; i <= steps; i++) {
        CGFloat f = (CGFloat)i / (CGFloat)steps;
        CGFloat angle = start + (sweep * f);
        CGFloat radius = innerRadius + ((outerRadius - innerRadius) * f);
        CGPoint point = CGPointMake(center.x + (radius * cos(angle)),
                                    center.y + (radius * sin(angle)));
        if (i == 0) {
            [p moveToPoint:point];
        } else {
            [p addLineToPoint:point];
        }
    }
    return p;
}

/// The bow, revealed only while the violin sounds, drawn across the strings.
- (UIBezierPath *)violinBowPath {
    UIBezierPath *p = [UIBezierPath bezierPath];
    if (self.instrument != A4InstrumentViolin) return p;

    [p moveToPoint:CGPointMake(13.0f, 75.0f)];
    [p addLineToPoint:CGPointMake(87.0f, 66.0f)];
    return p;
}

- (UIBezierPath *)strokePath {
    UIBezierPath *p = [UIBezierPath bezierPath];

    switch (self.instrument) {
        case A4InstrumentPiano: {
            [p appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(20.0f, 30.0f, 60.0f, 42.0f)
                                                     cornerRadius:6.0f]];
            for (CGFloat x = 35.0f; x <= 65.0f; x += 15.0f) {
                [p moveToPoint:CGPointMake(x, 31.0f)];
                [p addLineToPoint:CGPointMake(x, 71.0f)];
            }
            break;
        }

        case A4InstrumentViolin: {
            // Body: upper bout, pointed C-bout corners, wider lower bout.
            [p moveToPoint:CGPointMake(50.0f, 46.0f)];
            [p addCurveToPoint:CGPointMake(65.0f, 58.0f) controlPoint1:CGPointMake(59.0f, 46.0f) controlPoint2:CGPointMake(66.0f, 51.0f)];
            [p addLineToPoint:CGPointMake(60.0f, 65.0f)];
            [p addCurveToPoint:CGPointMake(56.0f, 72.0f) controlPoint1:CGPointMake(57.0f, 68.0f) controlPoint2:CGPointMake(56.0f, 69.0f)];
            [p addCurveToPoint:CGPointMake(61.0f, 79.0f) controlPoint1:CGPointMake(56.0f, 75.0f) controlPoint2:CGPointMake(58.0f, 76.0f)];
            [p addLineToPoint:CGPointMake(68.0f, 86.0f)];
            [p addCurveToPoint:CGPointMake(50.0f, 96.0f) controlPoint1:CGPointMake(68.0f, 92.0f) controlPoint2:CGPointMake(60.0f, 96.0f)];
            [p addCurveToPoint:CGPointMake(32.0f, 86.0f) controlPoint1:CGPointMake(40.0f, 96.0f) controlPoint2:CGPointMake(32.0f, 92.0f)];
            [p addLineToPoint:CGPointMake(39.0f, 79.0f)];
            [p addCurveToPoint:CGPointMake(44.0f, 72.0f) controlPoint1:CGPointMake(42.0f, 76.0f) controlPoint2:CGPointMake(44.0f, 75.0f)];
            [p addCurveToPoint:CGPointMake(40.0f, 65.0f) controlPoint1:CGPointMake(44.0f, 69.0f) controlPoint2:CGPointMake(43.0f, 68.0f)];
            [p addLineToPoint:CGPointMake(35.0f, 58.0f)];
            [p addCurveToPoint:CGPointMake(50.0f, 46.0f) controlPoint1:CGPointMake(34.0f, 51.0f) controlPoint2:CGPointMake(41.0f, 46.0f)];
            [p closePath];

            // Neck
            [p moveToPoint:CGPointMake(47.0f, 47.0f)];
            [p addLineToPoint:CGPointMake(47.0f, 26.0f)];
            [p moveToPoint:CGPointMake(53.0f, 47.0f)];
            [p addLineToPoint:CGPointMake(53.0f, 26.0f)];

            // Pegbox + scroll
            [p moveToPoint:CGPointMake(47.0f, 26.0f)];
            [p addCurveToPoint:CGPointMake(52.0f, 14.0f) controlPoint1:CGPointMake(43.0f, 20.0f) controlPoint2:CGPointMake(46.0f, 13.0f)];
            [p addCurveToPoint:CGPointMake(52.0f, 23.0f) controlPoint1:CGPointMake(58.0f, 15.0f) controlPoint2:CGPointMake(58.0f, 23.0f)];

            // Tuning pegs
            [p moveToPoint:CGPointMake(45.0f, 23.0f)];
            [p addLineToPoint:CGPointMake(38.0f, 21.0f)];
            [p moveToPoint:CGPointMake(55.0f, 23.0f)];
            [p addLineToPoint:CGPointMake(62.0f, 21.0f)];

            // f-holes, with the crossbar that makes them read as f-holes
            [p moveToPoint:CGPointMake(40.0f, 66.0f)];
            [p addCurveToPoint:CGPointMake(39.0f, 85.0f) controlPoint1:CGPointMake(35.0f, 70.0f) controlPoint2:CGPointMake(35.0f, 81.0f)];
            [p moveToPoint:CGPointMake(36.0f, 75.0f)];
            [p addLineToPoint:CGPointMake(44.0f, 76.0f)];
            [p moveToPoint:CGPointMake(60.0f, 66.0f)];
            [p addCurveToPoint:CGPointMake(61.0f, 85.0f) controlPoint1:CGPointMake(65.0f, 70.0f) controlPoint2:CGPointMake(65.0f, 81.0f)];
            [p moveToPoint:CGPointMake(56.0f, 75.0f)];
            [p addLineToPoint:CGPointMake(64.0f, 76.0f)];
            break;
        }

        case A4InstrumentFrenchHorn: {
            // Only the bell lives here; the coil is drawn by hornCoilLayer so it can
            // vibrate on its own. A wide opening with a shallow, flattened rim reads
            // as a french horn - a deep narrow cone reads as a trumpet.
            [p moveToPoint:CGPointMake(40.0f, 40.0f)];
            [p addCurveToPoint:CGPointMake(80.0f, 13.0f) controlPoint1:CGPointMake(56.0f, 38.0f) controlPoint2:CGPointMake(66.0f, 34.0f)];
            [p moveToPoint:CGPointMake(40.0f, 47.0f)];
            [p addCurveToPoint:CGPointMake(80.0f, 65.0f) controlPoint1:CGPointMake(56.0f, 49.0f) controlPoint2:CGPointMake(66.0f, 53.0f)];
            [p moveToPoint:CGPointMake(80.0f, 13.0f)];
            [p addCurveToPoint:CGPointMake(80.0f, 65.0f) controlPoint1:CGPointMake(86.0f, 29.0f) controlPoint2:CGPointMake(86.0f, 49.0f)];
            break;
        }

        case A4InstrumentSineWave:
            return [self sinePathWithPhase:0.0f];
    }

    return p;
}

- (UIBezierPath *)fillPath {
    UIBezierPath *p = [UIBezierPath bezierPath];

    if (self.instrument == A4InstrumentPiano) {
        for (CGFloat x = 30.5f; x <= 60.5f; x += 15.0f) {
            [p appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, 31.0f, 9.0f, 22.0f)
                                                     cornerRadius:2.5f]];
        }
    }

    return p;
}

/// The A key, held down while the piano tone sounds.
- (UIBezierPath *)pressedPath {
    UIBezierPath *p = [UIBezierPath bezierPath];

    if (self.instrument == A4InstrumentPiano) {
        [p appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(51.5f, 56.0f, 12.0f, 14.0f)
                                                 cornerRadius:2.0f]];
    }

    return p;
}

- (UIBezierPath *)sinePathWithPhase:(CGFloat)phase {
    UIBezierPath *p = [UIBezierPath bezierPath];
    const NSInteger steps = 64;
    const CGFloat originX = 11.0f, width = 78.0f, midY = 50.0f, amplitude = 17.0f;

    for (NSInteger i = 0; i <= steps; i++) {
        CGFloat t = (CGFloat)i / (CGFloat)steps;
        CGPoint point = CGPointMake(originX + (t * width),
                                    midY - (amplitude * sin((t * M_PI * 3.0f) + phase)));
        if (i == 0) {
            [p moveToPoint:point];
        } else {
            [p addLineToPoint:point];
        }
    }

    return p;
}

#pragma mark - Sine animation

- (void)startPlayingAnimations {
    if (self.legacyAppearance) return;   // the 2015 card has no vector glyph

    switch (self.instrument) {
        case A4InstrumentSineWave:   [self startSineAnimation]; break;
        case A4InstrumentViolin:     [self startBowAnimation];  break;
        case A4InstrumentFrenchHorn: [self startCoilAnimation]; break;
        default: break;
    }
}

- (void)stopPlayingAnimations {
    [self stopSineAnimation];
    [self.violinBowLayer removeAnimationForKey:@"a4.bow"];
    [self.hornCoilLayer removeAnimationForKey:@"a4.coil"];
}

/// The bow travels back and forth across the strings.
- (void)startBowAnimation {
    if (self.instrument != A4InstrumentViolin || self.glyphScale <= 0.0f) return;

    CGFloat travel = 9.0f * self.glyphScale;
    CABasicAnimation *bow = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    bow.fromValue = @(-travel);
    bow.toValue = @(travel);
    bow.duration = 1.1f;
    bow.autoreverses = YES;
    bow.repeatCount = HUGE_VALF;
    bow.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    bow.removedOnCompletion = NO;
    [self.violinBowLayer addAnimation:bow forKey:@"a4.bow"];
}

/// A fast, shallow rotation so the coil reads as buzzing rather than spinning.
- (void)startCoilAnimation {
    if (self.instrument != A4InstrumentFrenchHorn) return;

    CABasicAnimation *buzz = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    buzz.fromValue = @(-0.035f);
    buzz.toValue = @(0.035f);
    buzz.duration = 0.075f;
    buzz.autoreverses = YES;
    buzz.repeatCount = HUGE_VALF;
    buzz.removedOnCompletion = NO;
    [self.hornCoilLayer addAnimation:buzz forKey:@"a4.coil"];
}

- (void)startSineAnimation {
    if (self.instrument != A4InstrumentSineWave || self.glyphScale <= 0.0f) return;

    CGAffineTransform scale = CGAffineTransformMakeScale(self.glyphScale, self.glyphScale);
    NSMutableArray *frames = [NSMutableArray array];

    for (NSInteger i = 0; i <= (NSInteger)kSinePhaseSteps; i++) {
        CGFloat phase = (CGFloat)i / kSinePhaseSteps * 2.0f * (CGFloat)M_PI;
        UIBezierPath *path = [self sinePathWithPhase:phase];
        [path applyTransform:scale];
        [frames addObject:(id)path.CGPath];
    }

    CAKeyframeAnimation *travel = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    travel.values = frames;
    travel.duration = 1.6f;
    travel.repeatCount = HUGE_VALF;
    travel.calculationMode = kCAAnimationLinear;
    travel.removedOnCompletion = NO;
    [self.glyphStrokeLayer addAnimation:travel forKey:@"a4.sine"];
}

- (void)stopSineAnimation {
    [self.glyphStrokeLayer removeAnimationForKey:@"a4.sine"];
}

#pragma mark - State

- (void)setAccentColor:(UIColor *)accentColor {
    _accentColor = accentColor;
    [self updateForCurrentTraits];
}

- (void)setPlaying:(BOOL)playing {
    [self setPlaying:playing animated:NO];
}

- (void)setPlaying:(BOOL)playing animated:(BOOL)animated {
    BOOL changed = (_playing != playing);
    _playing = playing;

    if (changed && playing) {
        [self startPlayingAnimations];
    } else if (changed && !playing) {
        [self stopPlayingAnimations];
    }

    if (animated) {
        [UIView animateWithDuration:0.28
                              delay:0.0
             usingSpringWithDamping:0.9
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ [self applyStateColorsAnimated:YES]; }
                         completion:nil];
    } else {
        [self applyStateColorsAnimated:NO];
    }
}

- (void)setDimmed:(BOOL)dimmed animated:(BOOL)animated {
    CGFloat target = dimmed ? 0.45f : 1.0f;

    if (animated) {
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ self.alpha = target; }
                         completion:nil];
    } else {
        self.alpha = target;
    }
}

- (void)updateForCurrentTraits {
    UITraitCollection *traits = self.traitCollection;
    UIColor *accent = [self.accentColor resolvedColorWithTraitCollection:traits];

    self.backgroundColor = [UIColor a4CardSurface];
    self.layer.borderColor = [[UIColor a4CardBorder] resolvedColorWithTraitCollection:traits].CGColor;
    self.layer.shadowColor = [[UIColor a4ShadowColor] resolvedColorWithTraitCollection:traits].CGColor;

    self.accentFillLayer.colors = @[(id)accent.CGColor,
                                    (id)[accent a4Darkened:0.16f].CGColor];

    [self applyStateColorsAnimated:NO];
}

- (void)applyStateColorsAnimated:(BOOL)animated {
    if (self.legacyAppearance) {
        // 2015 styling: a flat sage card whose overlay flips while the tone sounds.
        self.backgroundColor = [UIColor a4LegacyCard];
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.25f;
        self.legacyOverlayLayer.geometryFlipped = self.playing;
        return;
    }

    UITraitCollection *traits = self.traitCollection;
    UIColor *accent = [self.accentColor resolvedColorWithTraitCollection:traits];
    UIColor *glyphColor = self.playing ? [UIColor whiteColor] : accent;

    // Inside a UIView animation these layer changes inherit its timing; outside one
    // they must not animate implicitly (layout and appearance changes call this too).
    if (!animated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    self.accentFillLayer.opacity = self.playing ? 1.0f : 0.0f;
    self.glyphStrokeLayer.strokeColor = glyphColor.CGColor;
    self.hornCoilLayer.strokeColor = glyphColor.CGColor;
    self.violinBowLayer.strokeColor = glyphColor.CGColor;
    self.violinBowLayer.opacity = (self.playing && self.instrument == A4InstrumentViolin) ? 1.0f : 0.0f;
    self.glyphFillLayer.fillColor = glyphColor.CGColor;
    self.glyphPressedLayer.fillColor = glyphColor.CGColor;
    self.glyphPressedLayer.opacity = self.playing ? 1.0f : 0.0f;
    if (!animated) {
        [CATransaction commit];
    }

    self.titleLabel.textColor = self.playing ? [UIColor whiteColor] : [UIColor a4TextPrimary];
    self.pitchLabel.textColor = self.playing ? [[UIColor whiteColor] colorWithAlphaComponent:0.85f]
                                             : [UIColor a4TextSecondary];

    self.iconContainer.backgroundColor = self.playing ? [[UIColor whiteColor] colorWithAlphaComponent:0.22f]
                                                      : [accent colorWithAlphaComponent:0.12f];
    self.iconView.tintColor = self.playing ? [UIColor whiteColor] : accent;

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:11.0f weight:UIImageSymbolWeightBold];
    self.iconView.image = [[UIImage systemImageNamed:(self.playing ? @"pause.fill" : @"play.fill")
                                   withConfiguration:config]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    self.layer.shadowOpacity = self.playing ? 0.26f : 0.16f;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateForCurrentTraits];
    }
}

@end
