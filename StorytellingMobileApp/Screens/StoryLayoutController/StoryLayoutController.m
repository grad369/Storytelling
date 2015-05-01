//
//  StoryLayoutController.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 01.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "StoryLayoutController.h"
#import "StoryLayout.h"
#import "DataManager.h"
#import "StoryEditorCellController.h"
#import "Settings.h"
#import "FullScreenController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ImagePresentAnimator.h"
#import "AVPlayerView.h"
#import <CoreMotion/CoreMotion.h>
#import "NSObject+MTKObserving.h"
#import "keypath.h"
#import "ActivityIndicator.h"

@interface StoryDragView : UIView
@property (weak, nonatomic) UIImageView *imageView;
@end
@implementation StoryDragView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.shadowOpacity = 0.75;
        self.layer.shadowOffset = CGSizeMake(5, 5);
        self.layer.shadowRadius = 8;
        
        // For visible shadow
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.clipsToBounds = YES;
        [self addSubview:view];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [view addSubview:imageView];
        self.imageView = imageView;
    }
    return self;
}
@end




@interface StoryLayoutController () <StoryEditorCellControllerDelegate, UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet ActivityIndicator *activityIndicator;
@property (strong, nonatomic) StoryLayout *layout;
@property (strong, nonatomic) NSMutableArray *cells;

@property (weak, nonatomic) StoryEditorCellController *currentEdititngController;
@property (weak, nonatomic) StoryDragView *currentEditingView;
@property (weak, nonatomic) UIImageView *selectedView;

@property (nonatomic) NSInteger newCellLocation;
@property (nonatomic) NSInteger currentPlayedVideo;
@property (nonatomic, readonly) StoryEditorCellController* currentPlayedVideoCellController;
@property (nonatomic, assign) NSInteger currentControllerIndex;
@property (nonatomic, assign) NSInteger controllerForShowFirstVideoIndex;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (assign, nonatomic) BOOL needMotionUpdates;
@end

@implementation StoryLayoutController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _currentControllerIndex = 0;
    _controllerForShowFirstVideoIndex = -1;
    
    __weak typeof (self) weakSelf = self;
    [SETTINGS observeProperty:@"videosType"
                withBlock:^(Settings *settings, id old, id newVal) {
                    [weakSelf setDefaultForEditorCellControllers];
    }];
}

- (void)dealloc
{
    [self stopUpdates];
    [SETTINGS removeAllObservationsOfObject:self];
}

-(StoryEditorCellController *)currentPlayedVideoCellController
{
    if (self.currentPlayedVideo < self.cells.count && self.currentPlayedVideo >= 0) {
        return self.cells[self.currentPlayedVideo];
    }
    return nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.needMotionUpdates) {
        [self startUpdates];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.view layoutIfNeeded]; // Why without it not work properly when present this in preview controller?
    [self makeLayout];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopUpdates];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    for (StoryEditorCellController *controller in self.cells) {
        controller.showWithAddtionZoom = NO;
    }
    [self makeLayout];
}

- (void)setStory:(Story *)story
{
    if (_story == story) {
        //return;
    }
    _story = story;
    
    _controllerForShowFirstVideoIndex = -1;
    _layout = [StoryLayout layoutWithName:self.story.layoutType];
    [self stopUpdates];
    self.zoomAnimationStateEnded = NO;
    [self createCells];
    [self makeLayout];
}

- (void)setLayout:(StoryLayout *)layout
{
    _layout = layout;
    self.story.layoutType = self.layout.name;
    [self makeLayout];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.canEdit) {
            for (StoryEditorCellController *controller in self.cells) {
                [controller clearFrame];
            }
        }
    });
}

- (void)setShowOnlyFirst:(BOOL)showOnlyFirst
{
    _showOnlyFirst = showOnlyFirst;
    self.zoomAnimationStateEnded = NO;
    [self makeLayout];
    
    if (self.showZoomAnimation) {
        [self beginZoomAnimation];
    }
}

- (void)createCells
{
    if (self.cells == nil) {
        self.cells = [NSMutableArray array];
        for (int i = 0; i < 4; i++) {
            StoryEditorCellController *controller = [[StoryEditorCellController alloc] initWithNibName:@"StoryEditorCellController" bundle:nil];
            [self.cells addObject:controller];
            [self.view insertSubview:controller.view belowSubview:self.activityIndicator];
        }
    }
    
    for (int i = 0; i < self.story.media.count; i++) {
        Media * media = self.story.media[i];
        StoryEditorCellController *controller = self.cells[i];
        controller.view.hidden = NO;
        controller.scrollView.userInteractionEnabled = self.canEdit;
        controller.showFullScreenPreview = self.showFullScreenPreview;
        controller.delegate = self;
        controller.showFullResolutionImage = self.canEdit;
        controller.showVideo = self.showVideo;
        controller.shouldAutoplay = YES;
        controller.canEdit = self.canEdit;
        controller.media = media;
        if (media.largeVideoURL == nil) {
            controller.showWithAddtionZoom = self.showZoomAnimation;
        }
    }
    
    for (int i = (int)self.story.media.count; i < 4; i++) {
        StoryEditorCellController *controller = self.cells[i];
        controller.view.hidden = YES;
    }
    
    if (self.canEdit && self.story.media.count > 1) {
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        [self.view addGestureRecognizer:recognizer];
    }
}

- (void)layoutOnlyFirst
{
    NSInteger index = 0;
    for (NSInteger i = 0; i < self.cells.count; i++) {
        StoryEditorCellController *controller = self.cells[i];
        if (controller.isVideo) {
            index = i;
            _controllerForShowFirstVideoIndex = i;
            break;
        }
    }
    NSArray *rects = [self.layout rectsScaledToSize:self.view.frame.size];
    for (int i = 0; i < rects.count; i++) {
        StoryEditorCellController *controller = self.cells[i];
        if (i == index) {
            controller.view.frame = self.view.bounds;
            controller.view.alpha = 1;
            [self.view insertSubview:controller.view belowSubview:self.activityIndicator];
        } else {
            CGRect frame = [rects[i] CGRectValue];
            frame.origin.x = CGRectGetMidX(frame);
            frame.origin.y = CGRectGetMidY(frame);
            frame.size = CGSizeMake(1, 1);
            controller.view.frame = frame;
            controller.view.alpha = 0;
        }
        
        [controller updateZoomScale];
    }
}

- (void)layoutNormal
{
    NSArray *rects = [self.layout rectsScaledToSize:self.view.frame.size];
    for (int i = 0; i < rects.count; i++) {
        StoryEditorCellController *controller = self.cells[i];
        controller.view.frame = [rects[i] CGRectValue];
        controller.view.alpha = 1;
        [controller updateZoomScale];
    }
}

- (void)makeLayout
{
    if (self.story == nil) {
        return;
    }
    
    if (self.showOnlyFirst) {
        [self layoutOnlyFirst];
    } else {
        [self layoutNormal];
    }
    
    if (!self.showZoomAnimation || self.zoomAnimationStateEnded) {
        [self setDefaultForEditorCellControllers];
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)recognizer
{
    if ((!self.showOnlyFirst && !self.canEdit) || self.story.preloaded.boolValue) {
        return;
    }
    
    static CGPoint location;
    NSArray *rects = [self.layout rectsScaledToSize:self.view.frame.size];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        location = [recognizer locationInView:self.view];
        
        if ([self.delegate respondsToSelector:@selector(layoutControllerDidBeginEdit:)]) {
            [self.delegate layoutControllerDidBeginEdit:self];
        }
        
        for (int i = 0; i < self.cells.count; i++) {
            StoryEditorCellController *controller = self.cells[i];
            if (CGRectContainsPoint(controller.view.frame, location)) {
                self.currentEdititngController = controller;
                self.newCellLocation = i;
                break;
            }
        }
        
        self.currentEdititngController.view.hidden = YES;
        
        CGRect frame = [self.dragView convertRect:self.currentEdititngController.scrollView.frame fromView:self.currentEdititngController.view];
        
        StoryDragView *view = [[StoryDragView alloc] initWithFrame:frame];
        self.currentEditingView = view;
        [self.dragView addSubview:view];
        
        view.imageView.frame = [self.currentEdititngController.imageView.superview convertRect:self.currentEdititngController.imageView.frame toView:self.currentEdititngController.view];
        view.imageView.image = self.currentEdititngController.imageView.image;
        
        [UIView animateWithDuration:0.3 animations:^{
            
            CGSize maxSize = self.view.bounds.size;
            const float scale = self.editMode == StoryLayoutControllerEditModeNormal ? 0.9 : 1.1;
            
            CGPoint location = [recognizer locationInView:self.dragView];
            CGRect frame = self.editMode == StoryLayoutControllerEditModeNormal ? view.bounds : [self.dragView convertRect:self.currentEdititngController.imageView.frame fromView:self.currentEdititngController.imageView.superview];
            float zoomX = frame.size.width / maxSize.width;
            float zoomY = frame.size.height / maxSize.height;
            float zoom = MAX(MAX(zoomX, zoomY), 1) / scale;
            frame = CGRectMake(location.x - (location.x - frame.origin.x) / zoom, location.y - (location.y - frame.origin.y) / zoom, frame.size.width / zoom, frame.size.height / zoom);
            view.frame = frame;
            
            if (self.editMode == StoryLayoutControllerEditModeNormal) {
                frame = view.imageView.frame;
                frame.origin.x *= scale;
                frame.origin.y *= scale;
                frame.size.width *= scale;
                frame.size.height *= scale;
                view.imageView.frame =  frame;
            } else {
                view.imageView.frame = view.bounds;
            }
        }];
        
        location = [recognizer locationInView:self.currentEditingView];
        
        if (!self.showOnlyFirst) {
            UIImage *image = [[UIImage imageNamed:@"selectedRect"] resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 5, 5)];
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            self.selectedView = imageView;
            self.selectedView.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                self.selectedView.alpha = 1;
            }];
            imageView.frame = frame;
            [self.dragView addSubview:imageView];
        }
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint newLocation = [recognizer locationInView:self.currentEditingView];
        CGRect frame = self.currentEditingView.frame;
        frame.origin.x += newLocation.x - location.x;
        frame.origin.y += newLocation.y - location.y;
        self.currentEditingView.frame = frame;
        newLocation = [recognizer locationInView:self.view];
        
        NSInteger prevLocation = self.newCellLocation;
        
        if (!CGRectContainsPoint(self.view.bounds, newLocation)) {
            self.newCellLocation = NSNotFound;
        } else if (self.showOnlyFirst) {
            self.newCellLocation = [self.cells indexOfObject:self.currentEdititngController];
        } else {
            for (int i = 0; i < rects.count; i++) {
                CGRect rect = [rects[i] CGRectValue];
                if (CGRectContainsPoint(rect, newLocation)) {
                    self.newCellLocation = i;
                    
                    if ([self.cells indexOfObject:self.currentEdititngController] != self.newCellLocation || prevLocation != self.newCellLocation) {
                        rect = [self.dragView convertRect:rect fromView:self.view];
                        
                        if (prevLocation == NSNotFound) {
                            // make it appear in place and not move due to
                            // animation below
                            self.selectedView.frame = rect;
                        }
                        
                        [UIView animateWithDuration:0.3 animations:^{
                            self.selectedView.alpha = 1;
                            self.selectedView.frame = rect;
                        }];                        
                    }
                    break;
                }
            }
        }
        
        if (prevLocation != self.newCellLocation) {
            if (prevLocation == NSNotFound) {
                if ([self.delegate respondsToSelector:@selector(layoutControllerDidExitFromDeleteZone:)]) {
                    [self.delegate layoutControllerDidExitFromDeleteZone:self];
                }
            }
            if (self.newCellLocation == NSNotFound) {
                if ([self.delegate respondsToSelector:@selector(layoutControllerDidEnterToDeleteZone:)]) {
                    [self.delegate layoutControllerDidEnterToDeleteZone:self];
                }
            }
        }
        
        if (self.newCellLocation == NSNotFound) {
            [UIView animateWithDuration:0.3 animations:^{
                self.selectedView.alpha = 0;
            }];
        }
        
        [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLayout) object:nil];
        [self performSelector:@selector(updateLayout) withObject:nil afterDelay:0.125];
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled) {
        
        if (self.newCellLocation != NSNotFound) {
            // Move
            if ([self.cells indexOfObject:self.currentEdititngController] != self.newCellLocation) {
                [self updateLayout];
            }
            
            [UIView animateWithDuration:0.25 animations:^{
                self.currentEditingView.frame = [self.dragView convertRect:self.currentEdititngController.scrollView.frame fromView:self.currentEdititngController.scrollView.superview];
                
                self.currentEditingView.imageView.frame = [self.currentEdititngController.imageView.superview convertRect:self.currentEdititngController.imageView.frame toView:self.currentEdititngController.scrollView.superview];
                
            } completion:^(BOOL finished) {
                [self.currentEditingView removeFromSuperview];
                self.currentEdititngController.view.hidden = NO;
                self.currentEdititngController = nil;
            }];
            
            [self makeLayout];
            
        } else {
            // Delete
            self.currentPlayedVideo = 0;
            
            [UIView animateWithDuration:0.3 animations:^{
                self.currentEditingView.transform = CGAffineTransformMakeScale(0, 0);
            } completion:^(BOOL finished) {
                [self.currentEdititngController.view removeFromSuperview];
                [self.currentEditingView removeFromSuperview];
            }];
            
            NSUInteger index = [self.cells indexOfObject:self.currentEdititngController];
            [self.cells removeObject:self.currentEdititngController];
            
            if (self.cells.count == 1) {
                [self.view removeGestureRecognizer:self.view.gestureRecognizers.lastObject];
            }
            self.currentEdititngController = nil;
            
            if ([self.delegate respondsToSelector:@selector(layoutController:didDeleteMediaAtIndex:)]) {
                [self.delegate layoutController:self didDeleteMediaAtIndex:index];
            }
        }
        
        [self.selectedView removeFromSuperview];
        
        [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLayout) object:nil];
        if ([self.delegate respondsToSelector:@selector(layoutControllerDidBeginEdit:)]) {
            [self.delegate layoutControllerDidEndEdit:self];
        }
    }
}

- (BOOL)isHaveAVPlayerView:(AVPlayerView *)playerView
{
    for (StoryEditorCellController *cellController in self.cells) {
        if ([cellController isHavePlayerView:playerView]) return YES;
    }
    return NO;
}

- (BOOL)isFirstAVPlayerView:(AVPlayerView *)playerView
{
    NSInteger index = _controllerForShowFirstVideoIndex < 0 ? 0 : _controllerForShowFirstVideoIndex;
    StoryEditorCellController *controller = self.cells[index];
    return [controller isHavePlayerView:playerView];
}

- (void)updateLayout
{
    if (self.newCellLocation != NSNotFound) {
        NSUInteger index = [self.cells indexOfObject:self.currentEdititngController];
        if (index == self.newCellLocation) {
            return;
        }
        StoryEditorCellController *controller = self.cells[self.newCellLocation];
        [self.cells replaceObjectAtIndex:self.newCellLocation withObject:self.currentEdititngController];
        [self.cells replaceObjectAtIndex:index withObject:controller];
        
        NSMutableOrderedSet *set = [self.story.media mutableCopy];
        [set exchangeObjectAtIndex:index withObjectAtIndex:self.newCellLocation];
        self.story.media = set;
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self makeLayout];
        } completion:nil];
    }
}

- (void)saveFrames
{
    for (int i = 0; i < self.cells.count; i++) {
        StoryEditorCellController *controller = self.cells[i];
        [controller saveFrame];
    }
}

- (void)setShowZoomAnimation:(BOOL)showZoomAnimation
{
    _showZoomAnimation = showZoomAnimation;
    
    for (StoryEditorCellController *controller in self.cells) {
        controller.showWithAddtionZoom = NO;
    }
}

- (void)beginZoomAnimation
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.zoomAnimationStateEnded) {
            [self performZoomAnimation];
        }
    });
    
    [self stopUpdates];
}

- (void)performZoomAnimation
{
    self.zoomAnimationStateEnded = YES;
    
    [UIView animateWithDuration:3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        for (StoryEditorCellController *controller in self.cells) {
            if (!controller.view.hidden) {
                [controller updateZoomScale];
            }
        }
    } completion:^(BOOL finished) {
        if (finished && self.motionManager == nil) {
            [self startUpdates];
            [self setDefaultForEditorCellControllers];
            self.needMotionUpdates = YES;
        }
    }];
}

- (void)setZoomAnimationStateEnded:(BOOL)zoomAnimationStateEnded
{
    _zoomAnimationStateEnded = zoomAnimationStateEnded;
    [self stopUpdates];
    
    for (StoryEditorCellController *controller in self.cells) {
        controller.showWithAddtionZoom = !zoomAnimationStateEnded;
    }
}

- (void)setShowFullScreenPreview:(BOOL)showFullScreenPreview
{
    _showFullScreenPreview = showFullScreenPreview;
    for (StoryEditorCellController *controller in self.cells) {
        controller.showFullScreenPreview = self.showFullScreenPreview;
    }
}

#pragma mark - CMMotion

- (void)startUpdates
{
    const float distance = 30;
    __weak typeof (self) weakSelf = self;
    __block CGPoint motionOffset = CGPointZero;
    
    // Create a CMMotionManager
    self.motionManager = [[CMMotionManager alloc] init];
    
    if ([self.motionManager isDeviceMotionAvailable] == YES) {
        // Assign the update interval to the motion manager
        self.motionManager.deviceMotionUpdateInterval = 1. / 30.;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            if (error) {
                NSLog(@"%s %@", __func__, error);
                return;
            }
            if (weakSelf.motionManager == nil) {
                return;
            }
            
            const float treshold = 0.1;
            CMRotationRate rotationRate = motion.rotationRate;
            if (fabs(rotationRate.x) < treshold) {
                rotationRate.x = 0;
            }
            if (fabs(rotationRate.y) < treshold) {
                rotationRate.y = 0;
            }
            motionOffset.x += rotationRate.y * distance * weakSelf.motionManager.deviceMotionUpdateInterval;
            motionOffset.y += rotationRate.x * distance * weakSelf.motionManager.deviceMotionUpdateInterval;
            motionOffset.x = MIN(MAX(motionOffset.x, -distance), distance);
            motionOffset.y = MIN(MAX(motionOffset.y, -distance), distance);
            
            for (StoryEditorCellController *controller in weakSelf.cells) {
                if (controller.isVideo) {
                    continue;
                }
                
                controller.showWithAddtionZoom = YES;
                controller.zoom = 0;
                controller.direction = CGPointMake(motionOffset.x * controller.length * 0.1, motionOffset.y * controller.length * 0.1);
                [controller updateZoomScale];
            }
        }];
    }
}

- (void)stopUpdates
{
    [self.motionManager stopDeviceMotionUpdates];
    self.motionManager = nil;
}

#pragma mark - StoryEditorCellController delegate

- (void)storyEditorCellControllerDidSelect:(StoryEditorCellController *)controller
{
    if (self.showFullScreenPreview) {
        [AVPlayerView sendControlBroadcast:@{@"autoplay":@NO} forPlayersPassingTest:nil];
        
        FullScreenController *fullScreenController = [[FullScreenController alloc] initWithNibName:@"FullScreenController" bundle:nil];
        fullScreenController.transitioningDelegate = self;
        fullScreenController.modalPresentationStyle = UIModalPresentationFullScreen;
        fullScreenController.media = controller.media;
        fullScreenController.story = self.story;
        fullScreenController.currentTime = [controller.playerView.player currentTime];
        [self presentViewController:fullScreenController animated:YES completion:nil];
    }
}

- (void)storyEditorCellControllerWillBeginLoading:(StoryEditorCellController *)controller
{
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

- (void)storyEditorCellControllerDidEndLoading:(StoryEditorCellController *)controller
{
    for (StoryEditorCellController *controller in self.cells) {
        if (controller.loading) {
            return;
        }
    }
    [self.activityIndicator stopAnimating];
    if (self.showZoomAnimation && !self.zoomAnimationStateEnded) {
        [self beginZoomAnimation];
    }
}

- (void)setDefaultForEditorCellControllers
{
    NSInteger index = _controllerForShowFirstVideoIndex < 0 ? 0 : _controllerForShowFirstVideoIndex;
    index = index >= self.cells.count ? 0 : index;
    
    if (self.showOnlyFirst) {
        
        StoryEditorCellController *controller = self.cells[index];
        controller.shouldAutoplay = YES;
        controller.shouldAutoRepeat = YES;
        controller.finishPlaying = nil;
        
        return;
    }
    
    if ([self countOfCellsWithVideo] == 1) {
        for (StoryEditorCellController *controller in self.cells) {
            if (controller.isVideo) {
                controller.shouldAutoplay = YES;
                controller.shouldAutoRepeat = YES;
                controller.finishPlaying = nil;
            }
        }
        return;
    }
    
    StoryEditorCellController *firstController = self.cells[index];
    
    for (StoryEditorCellController *controller in self.cells) {
        controller.shouldAutoRepeat = (SETTINGS.videosType == AutoPlayMultipleVideosTypeSimultaneous);
        controller.shouldAutoplay = (SETTINGS.videosType == AutoPlayMultipleVideosTypeSimultaneous || [controller isEqual:firstController]);
        if (SETTINGS.videosType == AutoPlayMultipleVideosTypeSynchronized) {
            controller.finishPlaying = ^(StoryEditorCellController *cellController) {
                    [self performSelector:@selector(nextPlayEditorCellController) withObject:nil afterDelay:0.0f];
            };
        }
        else
            controller.finishPlaying = nil;
    }
}

#pragma mark - Video control

- (void)nextPlayEditorCellController
{
    StoryEditorCellController *oldController = self.cells[_currentControllerIndex];
    
    if (++_currentControllerIndex >= self.cells.count)
        _currentControllerIndex = 0;
    
    StoryEditorCellController *cellController = self.cells[_currentControllerIndex];
   
    while (!cellController.isVideo && ![cellController isEqual:oldController] && cellController != nil) {
        if (++_currentControllerIndex >= self.cells.count)
            _currentControllerIndex = 0;
        cellController = self.cells[_currentControllerIndex];
    }
    
    cellController.shouldAutoplay = YES;
}

- (NSInteger)countOfCellsWithVideo
{
    NSInteger answer = 0;
    for (StoryEditorCellController *controller in self.cells) {
        if (controller.isVideo)
            answer++;
    }
    return answer;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(FullScreenController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    ImagePresentAnimator *animator = [self animatorForFullScreenController:presented];
    animator.presenting = YES;
    return animator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(FullScreenController *)dismissed
{
    ImagePresentAnimator *animator = [self animatorForFullScreenController:dismissed];
    return animator;
}

- (ImagePresentAnimator *)animatorForFullScreenController:(FullScreenController *)controller
{
    ImagePresentAnimator *animator = [ImagePresentAnimator new];
    
    Media *media = controller.media;
    NSInteger index = [self.story.media indexOfObject:media];
    StoryEditorCellController *storyController = self.cells[index];
    UIImage *image = storyController.imageView.image;
    animator.animationImage = image;
    if (media.largeVideoURL != nil) {
        UIView *view = controller.view.superview ? controller.view : storyController.playerView;
        animator.animationView = [view snapshotViewAfterScreenUpdates:NO];
        controller.seekView = [view snapshotViewAfterScreenUpdates:NO];
    }
    CALayer *layer = storyController.imageView.layer.presentationLayer;
    CGRect frame = [storyController.view convertRect:layer.frame fromView:storyController.view];
    animator.fromFrame = frame;
    frame = [self.parentViewController.view convertRect:storyController.view.bounds fromView:storyController.view];
    animator.fromImageBgFrame = frame;
    animator.contentMode = UIViewContentModeScaleAspectFit;
    return animator;
}

@end
