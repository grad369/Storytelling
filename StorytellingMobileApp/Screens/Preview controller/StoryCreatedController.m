//
//  StoryCreatedController.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 16.05.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "StoryCreatedController.h"

@interface StoryCreatedController ()

@end

@implementation StoryCreatedController

- (IBAction)didTapShareButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(storyCreatedControllerDidTapShareButton:)]) {
        [self.delegate storyCreatedControllerDidTapShareButton:self];
    }
}

- (IBAction)didTapDoneButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(storyCreatedControllerDidTapDoneButton:)]) {
        [self.delegate storyCreatedControllerDidTapDoneButton:self];
    }
}

@end
