//
//  UIColor+AppColors.m
//  A440
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "UIColor+AppColors.h"

static UIColor *A4Hex(uint32_t rgb) {
    return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0f
                          green:((rgb >> 8) & 0xFF) / 255.0f
                           blue:(rgb & 0xFF) / 255.0f
                          alpha:1.0f];
}

static UIColor *A4HexA(uint32_t rgb, CGFloat alpha) {
    return [A4Hex(rgb) colorWithAlphaComponent:alpha];
}

static UIColor *A4Dynamic(UIColor *light, UIColor *dark) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return tc.userInterfaceStyle == UIUserInterfaceStyleDark ? dark : light;
    }];
}

@implementation UIColor (AppColors)

#pragma mark - Grounds & surfaces

// Light mode lifts toward white; dark mode is a rich spruce green rather than black,
// with cards as translucent glass so they pick up the ground behind them.
+ (UIColor *)a4BackgroundTop    { return A4Dynamic(A4Hex(0xFCFDFB), A4Hex(0x0E4438)); }
+ (UIColor *)a4BackgroundBottom { return A4Dynamic(A4Hex(0xEEF3ED), A4Hex(0x05221C)); }
+ (UIColor *)a4Glow             { return A4Dynamic(A4HexA(0xFFFFFF, 0.95f), A4HexA(0x46D7B4, 0.20f)); }
+ (UIColor *)a4CardSurface      { return A4Dynamic(A4Hex(0xFFFFFF), A4HexA(0xFFFFFF, 0.085f)); }
+ (UIColor *)a4CardBorder       { return A4Dynamic(A4HexA(0x141E16, 0.06f), A4HexA(0xFFFFFF, 0.13f)); }
+ (UIColor *)a4ShadowColor      { return A4Dynamic(A4Hex(0x1C2C20), A4Hex(0x00140E)); }

#pragma mark - Text

+ (UIColor *)a4TextPrimary   { return A4Dynamic(A4Hex(0x1A201C), A4Hex(0xEAF4EF)); }
+ (UIColor *)a4TextSecondary { return A4Dynamic(A4Hex(0x5F6B63), A4Hex(0xA0BAB0)); }
+ (UIColor *)a4TextTertiary  { return A4Dynamic(A4Hex(0x93A099), A4Hex(0x75918A)); }

#pragma mark - Brand

+ (UIColor *)a4BrandTop    { return A4Hex(0x2FB99E); }
+ (UIColor *)a4BrandBottom { return A4Hex(0x0F5A49); }

#pragma mark - Instrument accents

// Dark variants run brighter so they hold up against the green ground.
+ (UIColor *)a4AccentPiano      { return A4Dynamic(A4Hex(0x4E63C8), A4Hex(0x8FA0F5)); }
+ (UIColor *)a4AccentViolin     { return A4Dynamic(A4Hex(0xD9654C), A4Hex(0xF79176)); }
+ (UIColor *)a4AccentFrenchHorn { return A4Dynamic(A4Hex(0xC7962F), A4Hex(0xEFC257)); }
+ (UIColor *)a4AccentSine       { return A4Dynamic(A4Hex(0x1E9E97), A4Hex(0x5EE0CF)); }

#pragma mark - Legacy (2015) design

+ (UIColor *)a4LegacyCard           { return A4Hex(0x769D82); }
+ (UIColor *)a4LegacyGradientTop    { return A4Hex(0x648C69); }
+ (UIColor *)a4LegacyGradientBottom { return A4Hex(0x3C5A3E); }
+ (UIColor *)a4LegacyNightBottom    { return A4HexA(0x283C29, 0.97f); }

#pragma mark - Helpers

+ (UIColor *)a4ColorWithLightHex:(uint32_t)lightHex darkHex:(uint32_t)darkHex {
    return A4Dynamic(A4Hex(lightHex), A4Hex(darkHex));
}

- (UIColor *)a4Darkened:(CGFloat)amount {
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat f = 1.0f - amount;
        return [UIColor colorWithRed:MAX(0.0f, r * f)
                               green:MAX(0.0f, g * f)
                                blue:MAX(0.0f, b * f)
                               alpha:a];
    }
    return self;
}

@end
