//
//  ModalPresentAnimator.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 14.05.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModalPresentAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic, assign) BOOL presenting;
@end
