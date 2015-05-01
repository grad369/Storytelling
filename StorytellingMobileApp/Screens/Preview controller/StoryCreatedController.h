//
//  StoryCreatedController.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 16.05.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StoryCreatedControllerDelegate;

@interface StoryCreatedController : UIViewController
@property (weak, nonatomic) id <StoryCreatedControllerDelegate> delegate;
@end


@protocol StoryCreatedControllerDelegate <NSObject>
- (void)storyCreatedControllerDidTapDoneButton:(StoryCreatedController *)controller;
- (void)storyCreatedControllerDidTapShareButton:(StoryCreatedController *)controller;
@end