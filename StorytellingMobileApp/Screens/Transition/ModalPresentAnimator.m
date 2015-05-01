//
//  ModalPresentAnimator.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 14.05.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "ModalPresentAnimator.h"

@implementation ModalPresentAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSTimeInterval animationDuration = [self transitionDuration:transitionContext];
    
    if (self.presenting) {
        [transitionContext.containerView addSubview:toViewController.view];
        CGRect frame = fromViewController.view.frame;
        frame.origin.y = CGRectGetHeight(frame);
        toViewController.view.frame = frame;
        
        [UIView animateWithDuration:animationDuration animations:^{
            toViewController.view.frame = fromViewController.view.frame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        [transitionContext.containerView insertSubview:toViewController.view atIndex:0];
        [UIView animateWithDuration:animationDuration animations:^{
            CGRect frame = fromViewController.view.frame;
            frame.origin.y = CGRectGetHeight(frame);
            fromViewController.view.frame = frame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
