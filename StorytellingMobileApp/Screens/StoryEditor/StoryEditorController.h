//
//  StoryEditorController.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 24.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StoryLayoutController.h"

@class Story;
@protocol StoryEditorControllerDelegate;

@interface StoryEditorController : UIViewController <StoryLayoutControllerDelegate>

@property (strong, nonatomic) NSArray *selectedAssets;
@property (weak, nonatomic) id <StoryEditorControllerDelegate> delegate;

@property (strong, nonatomic) Story *story;
@end


@protocol StoryEditorControllerDelegate <NSObject>

- (void)storyEditorController:(StoryEditorController *)controller didUpdateStory:(Story *)story;

@end