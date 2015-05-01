//
//  ImagePresentAnimator.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 24.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVPlayerView;

@interface ImagePresentAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL presenting;
@property (strong, nonatomic) UIImage *animationImage;
@property (strong, nonatomic) UIView *animationView;
@property (nonatomic, assign) CGRect fromFrame;
@property (nonatomic, assign) CGRect fromImageBgFrame;
@property (nonatomic, assign) UIViewContentMode contentMode;
@property (nonatomic, assign) BOOL zoomParentController;

@end


// Must be implement in ToViewController
@protocol ImagePresentAnimatorToViewControllerDelegate <NSObject>
@required
- (CGRect)imagePresentAnimatorFrameForFullScreenImage:(ImagePresentAnimator *)animator;
@optional
- (void)imagePresentAnimatorDidBeginPresentAnimation:(ImagePresentAnimator *)animator;
- (void)imagePresentAnimatorDidEndPresentAnimation:(ImagePresentAnimator *)animator;
- (void)imagePresentAnimatorDidBeginDismissAnimation:(ImagePresentAnimator *)animator;
- (void)imagePresentAnimatorDidEndDismissAnimation:(ImagePresentAnimator *)animator;
@end