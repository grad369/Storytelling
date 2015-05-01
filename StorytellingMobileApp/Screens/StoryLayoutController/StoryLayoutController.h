//
//  StoryLayoutController.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 01.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    StoryLayoutControllerEditModeNormal,
    StoryLayoutControllerEditModeZoom,
} StoryLayoutControllerEditMode;

@class Story, StoryLayout, AVPlayerView;
@protocol StoryLayoutControllerDelegate;

@interface StoryLayoutController : UIViewController

@property (strong, nonatomic) Story *story;
@property (nonatomic) BOOL canEdit;
@property (nonatomic) StoryLayoutControllerEditMode editMode;
@property (nonatomic) BOOL showOnlyFirst;
@property (nonatomic) BOOL showVideo;
@property (nonatomic) BOOL showFullScreenPreview;
@property (nonatomic) BOOL showZoomAnimation;
@property (nonatomic) BOOL zoomAnimationStateEnded;

@property (weak, nonatomic) id <StoryLayoutControllerDelegate> delegate;
@property (weak, nonatomic) UIView *dragView;

- (void)setLayout:(StoryLayout *)layout;
- (void)setShowOnlyFirst:(BOOL)showOnlyFirst;
- (void)saveFrames;

- (void)beginZoomAnimation;
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer;

- (BOOL)isHaveAVPlayerView:(AVPlayerView *)playerView;
- (BOOL)isFirstAVPlayerView:(AVPlayerView *)playerView;
@end


@protocol StoryLayoutControllerDelegate <NSObject>
@optional
- (void)layoutController:(StoryLayoutController *)controller didDeleteMediaAtIndex:(NSInteger)index;
- (void)layoutControllerDidBeginEdit:(StoryLayoutController *)controller;
- (void)layoutControllerDidEndEdit:(StoryLayoutController *)controller;
- (void)layoutControllerDidEnterToDeleteZone:(StoryLayoutController *)controller;
- (void)layoutControllerDidExitFromDeleteZone:(StoryLayoutController *)controller;
@end