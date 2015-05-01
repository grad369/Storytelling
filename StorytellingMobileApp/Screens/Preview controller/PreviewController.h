//
//  PreviewController.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 09.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConvertStoryLocal.h"

extern NSString* kDidUploadStoryNotification;

@class Story, StoryLayoutController;
@protocol PreviewControllerDelegate;

@interface PreviewController : UIViewController

@property (strong, nonatomic) Story *story;
@property (weak, nonatomic) id <PreviewControllerDelegate> delegate;
@property (strong, nonatomic) ConvertStoryLocal* convertOperation;
@property (strong, nonatomic, readonly) StoryLayoutController *layoutController;
@property (strong, nonatomic) NSOperationQueue* processingQueue;

@property (nonatomic) BOOL showFromHomeScreen;
@property (nonatomic) BOOL showFromHomeScreenFullScreen;

@property (nonatomic) BOOL showFromEditor;

- (void)setShowFromHomeScreenFullScreen:(BOOL)showFromHomeScreenFullScreen;
- (IBAction)didTapShareButton:(UIButton *)sender;
- (void)showActivityControllerWithUrl:(NSURL *)url completion:(void(^)())completion;
@end


@protocol PreviewControllerDelegate <NSObject>
@optional
- (void)previewControllerDidTapShare:(PreviewController *)controller;
- (void)previewControllerDidTapClose:(PreviewController *)controller;

@end