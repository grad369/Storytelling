//
//  StoryEditorCellController.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 01.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MPMoviePlayerController, Media, AVPlayerView;
@protocol StoryEditorCellControllerDelegate;


@interface StoryEditorCellController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet AVPlayerView *playerView;

@property (weak, nonatomic) id <StoryEditorCellControllerDelegate> delegate;
@property (strong, nonatomic) Media *media;
@property (nonatomic) BOOL showFullResolutionImage;
@property (nonatomic) BOOL showVideo;
@property (nonatomic) BOOL canEdit;
@property (nonatomic) BOOL shouldAutoplay;
@property (nonatomic) BOOL shouldAutoRepeat;
@property (nonatomic) BOOL showFullScreenPreview;

// For animation
@property (nonatomic) CGFloat zoom;
@property (nonatomic) CGFloat length;
@property (nonatomic) CGPoint direction;
@property (nonatomic) BOOL showWithAddtionZoom;
@property (nonatomic, readonly) BOOL isVideo;

- (void)updateZoomScale;
- (void)saveFrame;
- (void)clearFrame;

@property (nonatomic, copy) void(^finishPlaying)(StoryEditorCellController*);
- (BOOL)isHavePlayerView:(AVPlayerView *)playerView;

@property (nonatomic, readonly) BOOL readyForDisplay;
@property (nonatomic, readonly) BOOL readyForPlayback;
@property (nonatomic, readonly) BOOL loading;

@end


@protocol StoryEditorCellControllerDelegate <NSObject>

- (void)storyEditorCellControllerDidSelect:(StoryEditorCellController *)controller;
- (void)storyEditorCellControllerWillBeginLoading:(StoryEditorCellController *)controller;
- (void)storyEditorCellControllerDidEndLoading:(StoryEditorCellController *)controller;

@end