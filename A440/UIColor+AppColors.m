//
//  UIColor+AppColors.m
//  A440
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "UIColor+AppColors.h"

@implementation UIColor (AppColors)

// Main button background color (sage green) - supports Dark Mode
+ (UIColor *)appColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                // Slightly lighter in dark mode for better visibility
                return [UIColor colorWithRed:138.0f/255.0f
                                       green:177.0f/255.0f
                                        blue:150.0f/255.0f
                                       alpha:1.0f];
            } else {
                // Original sage green for light mode
                return [UIColor colorWithRed:118.0f/255.0f
                                       green:157.0f/255.0f
                                        blue:130.0f/255.0f
                                       alpha:1.0f];
            }
        }];
    }
    // Fallback for iOS 12
    return [UIColor colorWithRed:118.0f/255.0f
                           green:157.0f/255.0f
                            blue:130.0f/255.0f
                           alpha:1.0f];
}

// Dark green for gradient (daytime bottom) - supports Dark Mode
+ (UIColor *)appColor1 {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                // Slightly lighter dark green for dark mode
                return [UIColor colorWithRed:80.0f/255.0f
                                       green:110.0f/255.0f
                                        blue:82.0f/255.0f
                                       alpha:1.0f];
            } else {
                return [UIColor colorWithRed:60.0f/255.0f
                                       green:90.0f/255.0f
                                        blue:62.0f/255.0f
                                       alpha:1.0f];
            }
        }];
    }
    return [UIColor colorWithRed:60.0f/255.0f
                           green:90.0f/255.0f
                            blue:62.0f/255.0f
                           alpha:1.0f];
}

// Medium green for gradient (daytime top) - supports Dark Mode
+ (UIColor *)appColor2 {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                // Lighter medium green for dark mode
                return [UIColor colorWithRed:120.0f/255.0f
                                       green:160.0f/255.0f
                                        blue:125.0f/255.0f
                                       alpha:1.0f];
            } else {
                return [UIColor colorWithRed:100.0f/255.0f
                                       green:140.0f/255.0f
                                        blue:105.0f/255.0f
                                       alpha:1.0f];
            }
        }];
    }
    return [UIColor colorWithRed:100.0f/255.0f
                           green:140.0f/255.0f
                            blue:105.0f/255.0f
                           alpha:1.0f];
}

// Very dark green for gradient (nighttime) - supports Dark Mode
+ (UIColor *)appColor3 {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                // Slightly lighter very dark green for dark mode
                return [UIColor colorWithRed:60.0f/255.0f
                                       green:80.0f/255.0f
                                        blue:61.0f/255.0f
                                       alpha:0.97f];
            } else {
                return [UIColor colorWithRed:40.0f/255.0f
                                       green:60.0f/255.0f
                                        blue:41.0f/255.0f
                                       alpha:0.97f];
            }
        }];
    }
    return [UIColor colorWithRed:40.0f/255.0f
                           green:60.0f/255.0f
                            blue:41.0f/255.0f
                           alpha:0.97f];
}

@end
