//
//  UIImageView+Circle.m
//  StorytellingMobileApp
//
//  Created by vaskov on 27.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "UIImageView+Circle.h"

static BOOL circle;

@implementation UIImageView (Circle)

@dynamic isCircle;
- (void)setCircle:(BOOL)isCircle
{
    circle = isCircle;
    
    if (!isCircle) return;
    
    CALayer *layer = self.layer;
    layer.borderColor = [[UIColor whiteColor] CGColor];
    layer.borderWidth = 1.0f;
    layer.cornerRadius = self.frame.size.width/2;
    layer.masksToBounds = YES;
}

- (BOOL)isCircle
{
    return circle;
}

@end
