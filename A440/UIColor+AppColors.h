//
//  UIColor+AppColors.h
//  A440
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//
//  A440 color system (2026 refresh).
//  Spruce-biased neutral grounds with four instrument accent colors that
//  double as wayfinding. Every color is dynamic (light / dark aware).
//

#import <UIKit/UIKit.h>

@interface UIColor (AppColors)

#pragma mark - Grounds & surfaces
+ (UIColor *)a4BackgroundTop;      // top of the screen gradient
+ (UIColor *)a4BackgroundBottom;   // bottom of the screen gradient
+ (UIColor *)a4Glow;               // subtle radial glow behind the header
+ (UIColor *)a4CardSurface;        // resting instrument-card fill
+ (UIColor *)a4CardBorder;         // hairline card border
+ (UIColor *)a4ShadowColor;        // card drop shadow

#pragma mark - Text
+ (UIColor *)a4TextPrimary;
+ (UIColor *)a4TextSecondary;
+ (UIColor *)a4TextTertiary;

#pragma mark - Brand (tuning fork mark)
+ (UIColor *)a4BrandTop;
+ (UIColor *)a4BrandBottom;

#pragma mark - Instrument accents
+ (UIColor *)a4AccentPiano;
+ (UIColor *)a4AccentViolin;
+ (UIColor *)a4AccentFrenchHorn;
+ (UIColor *)a4AccentSine;

#pragma mark - Legacy (2015) design
// Deliberately fixed, not appearance-aware: the original app predated Dark Mode
// and the shake-to-compare toggle should show it exactly as it shipped.
+ (UIColor *)a4LegacyCard;            // sage green instrument button
+ (UIColor *)a4LegacyGradientTop;     // daytime background, top
+ (UIColor *)a4LegacyGradientBottom;  // daytime background, bottom
+ (UIColor *)a4LegacyNightBottom;     // night background, bottom

#pragma mark - Helpers
/// Builds a dynamic color from two packed 0xRRGGBB values (light / dark).
+ (UIColor *)a4ColorWithLightHex:(uint32_t)lightHex darkHex:(uint32_t)darkHex;
/// Returns a darker variant of the receiver (for the active-card gradient).
- (UIColor *)a4Darkened:(CGFloat)amount;

@end
