//
//  ImagePresentAnimator.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 24.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "ImagePresentAnimator.h"

#define kSnapshotTag 483959

@implementation ImagePresentAnimator


- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.4f;
}

-(void)moveAnchorOfLayer:(CALayer*)layer toCenterOfRect:(CGRect)rect
{
    CGRect frameRect = layer.frame;
    
    CGPoint newAnchor =
    CGPointMake(
                (rect.origin.x + rect.size.width/2)/frameRect.size.width,
                (rect.origin.y + rect.size.height/2)/frameRect.size.height
                );
    
    CGPoint newPosition =
    CGPointMake(
                layer.position.x + (newAnchor.x - layer.anchorPoint.x)*frameRect.size.width,
                layer.position.y + (newAnchor.y - layer.anchorPoint.y)*frameRect.size.height
                );
    
    layer.anchorPoint = newAnchor;
    layer.position = newPosition;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSTimeInterval animationDuration = [self transitionDuration:transitionContext];
    
    if (self.presenting) {
        NSAssert([toViewController respondsToSelector:@selector(imagePresentAnimatorFrameForFullScreenImage:)], @"ToViewController must implement ImagePresentAnimatorToViewControllerDelegate");
        
        [transitionContext.containerView addSubview:toViewController.view];
        toViewController.view.frame = fromViewController.view.frame;
        [toViewController.view layoutIfNeeded];
        
        id <ImagePresentAnimatorToViewControllerDelegate> to = (id <ImagePresentAnimatorToViewControllerDelegate>)toViewController;
        CGRect toFrame = [to imagePresentAnimatorFrameForFullScreenImage:self];
        
        UIView *view = [[UIView alloc] initWithFrame:self.fromImageBgFrame];
        view.backgroundColor = [UIColor clearColor];
        view.clipsToBounds = YES;
        [transitionContext.containerView addSubview:view];
        
        if (self.animationView == nil) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.fromFrame];
            imageView.contentMode = self.contentMode;
            imageView.clipsToBounds = YES;
            imageView.image = self.animationImage;
            imageView.alpha = 0;
            [view addSubview:imageView];
            self.animationView = imageView;
        } else {
            self.animationView.frame = self.fromFrame;
        }
        
        self.animationView.alpha = 0;
        [view addSubview:self.animationView];

        
        [self moveAnchorOfLayer:fromViewController.view.layer toCenterOfRect:self.fromFrame];
        
        double opacityChangeTimeRatio = 0.2;
        
        [UIView animateWithDuration:animationDuration*opacityChangeTimeRatio animations:^{
            self.animationView.alpha = 1;
        }];
        
        [UIView animateWithDuration:animationDuration*(1-opacityChangeTimeRatio)
                              delay:animationDuration*opacityChangeTimeRatio
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             view.frame = toFrame;
                             self.animationView.frame = view.bounds;
                             self.animationView.alpha = 1;
                             if ([to respondsToSelector:@selector(imagePresentAnimatorDidBeginPresentAnimation:)]) {
                                 [to imagePresentAnimatorDidBeginPresentAnimation:self];
                             }
                             
                             if (self.zoomParentController) {
                                 fromViewController.view.transform = CGAffineTransformMakeScale(0.5, 0.5);
                             }
                         } completion:^(BOOL finished) {
                             [self.animationView removeFromSuperview];
                             if ([to respondsToSelector:@selector(imagePresentAnimatorDidEndPresentAnimation:)]) {
                                 [to imagePresentAnimatorDidEndPresentAnimation:self];
                             }
                             
                             [transitionContext completeTransition:YES];
                             fromViewController.view.transform = CGAffineTransformIdentity;
                         }];
    } else {
        NSAssert([fromViewController respondsToSelector:@selector(imagePresentAnimatorFrameForFullScreenImage:)], @"FromViewController must implement ImagePresentAnimatorToViewControllerDelegate");
        
        id <ImagePresentAnimatorToViewControllerDelegate> from = (id <ImagePresentAnimatorToViewControllerDelegate>)fromViewController;
        CGRect toFrame = [from imagePresentAnimatorFrameForFullScreenImage:self];
        
        [transitionContext.containerView insertSubview:toViewController.view atIndex:0];
        
        UIView *view = [[UIView alloc] initWithFrame:toFrame];
        view.backgroundColor = [UIColor clearColor];
        view.clipsToBounds = YES;
        [transitionContext.containerView addSubview:view];
        
        if (self.animationView == nil) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.bounds];
            imageView.contentMode = self.contentMode;
            imageView.clipsToBounds = YES;
            imageView.image = self.animationImage;
            self.animationView = imageView;
        } else {
            self.animationView.frame = view.bounds;
        }
        
        self.animationView.alpha = 1;
        [view addSubview:self.animationView];
        double opacityChangeTimeRatio = 0.2;
        
        [self moveAnchorOfLayer:toViewController.view.layer toCenterOfRect:self.fromFrame];
        
        if (self.zoomParentController) {
            toViewController.view.transform = CGAffineTransformMakeScale(0.5, 0.5);
        }
        
        [UIView animateWithDuration:animationDuration*(1-opacityChangeTimeRatio) animations:^{
            view.frame = self.fromImageBgFrame;
            self.animationView.frame = self.fromFrame;
            toViewController.view.transform = CGAffineTransformIdentity;
            if ([from respondsToSelector:@selector(imagePresentAnimatorDidBeginDismissAnimation:)]) {
                [from imagePresentAnimatorDidBeginDismissAnimation:self];
            }
        } ];
        
        [UIView animateWithDuration:animationDuration*opacityChangeTimeRatio
                              delay:animationDuration*(1-opacityChangeTimeRatio)
                            options:UIViewAnimationOptionCurveEaseInOut
         animations:^{
             self.animationView.alpha = 0;
         } completion:^(BOOL finished) {
             [self.animationView removeFromSuperview];
             [transitionContext completeTransition:YES];
             
             if ([from respondsToSelector:@selector(imagePresentAnimatorDidBeginDismissAnimation:)]) {
                 [from imagePresentAnimatorDidEndDismissAnimation:self];
             }
         }];
    }
}

@end
