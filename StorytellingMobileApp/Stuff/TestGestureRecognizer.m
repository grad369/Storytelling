//
//  TestGestureRecognizer.m
//  StorytellingMobileApp
//
//  Created by Леонід on 09.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "TestGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation TestGestureRecognizer

-(id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        self.delaysTouchesBegan = NO;
        self.delaysTouchesEnded = NO;
        self.cancelsTouchesInView = NO;
    }
    return self;
}

-(void)reset
{
    //NSLog(@"reset");
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateRecognized;
}


-(BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    return NO;
}

-(BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    return NO;
}

@end
