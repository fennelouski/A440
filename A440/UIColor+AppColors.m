//
//  UIColor+AppColors.m
//  A440
//
//  Created by Developer Nathan on 2/25/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "UIColor+AppColors.h"

@implementation UIColor (AppColors)

// Main button background color (sage green)
+ (UIColor *)appColor {
    return [UIColor colorWithRed:118.0f/255.0f
                           green:157.0f/255.0f
                            blue:130.0f/255.0f
                           alpha:1.0f];
}

// Dark green for gradient (daytime bottom)
+ (UIColor *)appColor1 {
    return [UIColor colorWithRed:60.0f/255.0f
                           green:90.0f/255.0f
                            blue:62.0f/255.0f
                           alpha:1.0f];
}

// Medium green for gradient (daytime top)
+ (UIColor *)appColor2 {
    return [UIColor colorWithRed:100.0f/255.0f
                           green:140.0f/255.0f
                            blue:105.0f/255.0f
                           alpha:1.0f];
}

// Very dark green for gradient (nighttime)
+ (UIColor *)appColor3 {
    return [UIColor colorWithRed:40.0f/255.0f
                           green:60.0f/255.0f
                            blue:41.0f/255.0f
                           alpha:0.97f];
}

@end
