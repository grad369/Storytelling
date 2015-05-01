//
//  NestedScrollView.m
//  StorytellingMobileApp
//
//  Created by Leonid Usov on 09.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "NestedScrollView.h"

@interface NestedScrollView ()
@property (nonatomic, strong) UIEvent* innerTouchEvent;
@end

@implementation NestedScrollView

-(BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    if (self.noTouchCancelInThisView) {
        BOOL isDescendant = [view isDescendantOfView:self.noTouchCancelInThisView];
        return NO == isDescendant;
    }
    return YES;
}

@end
