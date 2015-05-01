//
//  StoryEditorCellController.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 01.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "StoryEditorCellController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "DataManager.h"
#import <TargetConditionals.h>
#import "Cache.h"
#import "AVPlayerView.h"
#import "Settings.h"

#import "NSObject+MTKObserving.h"
#import "keypath.h"

#define kZoomAnimationDuration 3

@interface StoryEditorCellController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *imageBg;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *videoIcon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

@property (nonatomic) CGRect frameRect;

@property (nonatomic) BOOL isVideo;

@property (atomic) NSInteger activityReqeusts;

@property (nonatomic, copy) void(^animationCompletionBlock)();

@end

@implementation StoryEditorCellController


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.button.enabled = self.showFullScreenPreview;
    [self setupObservations];
    
    __weak typeof(self) selfId = self;
    _playerView.finishPlaying = ^(AVPlayerView *player){
        if (selfId.finishPlaying != nil)
            selfId.finishPlaying(selfId);        
    };
}

-(void)setupObservations
{
    [self observeObject:self
               property:@keypath(self.playerView.player.rate)
              withBlock:^(__typeof(self) self, id object, id old, id newVal) {
                  float rate = [newVal floatValue];
                  BOOL hidden = rate > 0 || self.playerView.playerLayer.readyForDisplay;
                  
                  [self.imageView setHidden:hidden];
                  [self.playerView setHidden:!hidden];
                  CATransition* t = [CATransition animation];
                  t.duration = 0.1;
                  [self.imageView.layer addAnimation:t forKey:kCATransition];
              }];
}

- (BOOL)loading
{
    return self.activityReqeusts > 0;
}

-(void)requestActivity:(BOOL)rotating
{
    if (rotating) {
        if (self.activityReqeusts == 0) {
            if ([self.delegate respondsToSelector:@selector(storyEditorCellControllerWillBeginLoading:)]) {
                [self.delegate storyEditorCellControllerWillBeginLoading:self];
            }
        }
        self.activityReqeusts++;
    }
    else{
        self.activityReqeusts--;
        if (self.activityReqeusts == 0) {
            if ([self.delegate respondsToSelector:@selector(storyEditorCellControllerDidEndLoading:)]) {
                [self.delegate storyEditorCellControllerDidEndLoading:self];
            }
        }
    }
}

-(void)dealloc
{
    [self removeAllObservations];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateZoomScale];
}

- (void)setMedia:(Media *)media
{
    if  ( _media == media ) {
        //return;
    }
    
    _media = media;
    
    self.isVideo = media.largeVideoURL != nil;
    // video icon not needed as we are playing the video
    self.videoIcon.hidden = !(self.isVideo && self.canEdit);
    self.shouldAutoplay = NO;
    self.imageView.hidden = NO;
    self.imageView.image = nil;
    self.frameRect = [media.frameRect CGRectValue];
    self.activityReqeusts = 0;
    [self requestActivity:YES];
    [self.playerView setContentURL:nil];
    [self stopAnimations];
    [self generateRandomZoom];
    
    if (self.showVideo && self.isVideo) {
        //[self requestActivity:YES];
        [Cache videoUrlForKey:media.largeVideoURL block:^(TMDiskCache *cache, NSString *key, id<NSCoding> object, NSURL *fileURL) {
            // use NSDefaultRunLoopMode to make sure that the message will be delivered only after the
            // scroll has finished
            [self performSelector:@selector(applyVideoWithURLMediaArgs:) withObject:@[fileURL,media] afterDelay:1 inModes:@[NSDefaultRunLoopMode]];
        }];
    }
    else {
        [self.playerView setContentURL:nil];
    }
    
    [Cache imageForKey:media.largeImageURL fullResolutionImage:self.showFullResolutionImage block:^(TMCache *cache, NSString *key, UIImage *object) {
        if (_media == media) {
            self.imageView.image = object;
            self.contentViewWidthConstraint.constant = object.size.width;
            self.contentViewHeightConstraint.constant = object.size.height;
            [self updateZoomScale];
            if (self.canEdit && CGRectEqualToRect([media.frameRect CGRectValue], CGRectZero)) {
                self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
            }
            [self requestActivity:NO];
        }
    }];
}

- (void)stopAnimations
{
    [self.imageView.layer removeAllAnimations];
    [self.playerView.layer removeAllAnimations];
}

- (void)setShowFullScreenPreview:(BOOL)showFullScreenPreview
{
    _showFullScreenPreview = showFullScreenPreview;
    self.button.enabled = self.showFullScreenPreview;
}

-(void)applyVideoWithURLMediaArgs:(NSArray*)args
{
    NSURL* fileURL = args[0];
    Media* media = args[1];
    if (_media == media) {
        [self.playerView setContentURL:fileURL];
        //[self requestActivity:NO];
    }
}

-(void)setShouldAutoplay:(BOOL)shouldAutoplay
{
    if (self.isVideo)
        self.playerView.autoplay = shouldAutoplay;
}

-(BOOL)shouldAutoplay
{
    return self.playerView.autoplay;
}

- (void)setShouldAutoRepeat:(BOOL)shouldAutoRepeat
{
    if (self.isVideo)
        self.playerView.autorepeat = shouldAutoRepeat;
}

- (BOOL)shouldAutoRepeat
{
    return self.playerView.autorepeat;
}

- (void)setCanEdit:(BOOL)canEdit
{
    _canEdit = canEdit;
    self.scrollView.hidden = !canEdit;
}

- (void)setShowWithAddtionZoom:(BOOL)showWithAddtionZoom
{
    if (_showWithAddtionZoom != showWithAddtionZoom) {
        _showWithAddtionZoom = showWithAddtionZoom;
        [self generateRandomZoom];
    }
}

- (void)generateRandomZoom
{
    self.length = (arc4random() % RAND_MAX) * 0.03 / (float)RAND_MAX + 0.03;
    float angle = (arc4random() % RAND_MAX) * M_PI * 2 / (float)RAND_MAX;
    CGPoint direction = CGPointMake(sin(angle) * self.length, cos(angle) * self.length);
    self.zoom = 0.02;
    self.direction = direction;
}

- (void)updateZoomScale
{
    if (self.imageView.image == nil || self.media == nil) {
        return;
    }
    
    if (self.canEdit) {
        [self calculateScrollView];
    } else {
        [self calculateFrames];
    }
}

- (void)calculateFrames
{
    [self.view layoutIfNeeded];
    
    UIImage *image = self.imageView.image;
    CGRect rect = [self.media.frameRect CGRectValue];
    float sizeW = CGRectGetWidth(rect) * image.size.width;
    float sizeH = CGRectGetHeight(rect) * image.size.height;
    
    float minScaleX = CGRectGetWidth(self.view.frame) / image.size.width;
    float minScaleY = CGRectGetHeight(self.view.frame) / image.size.height;
    float minScale = MAX(minScaleX, minScaleY);
    
    float addZoom = self.showWithAddtionZoom ? self.zoom : 0;
    float directionX = self.showWithAddtionZoom ? self.direction.x : 0;
    float directionY = self.showWithAddtionZoom ? self.direction.y : 0;
    
    float scaleX = CGRectGetWidth(self.view.frame) / sizeW;
    float scaleY = CGRectGetHeight(self.view.frame) / sizeH;
    float scale = MIN(scaleX, scaleY) + addZoom;
    scale = MAX(scale, minScale);
    
    float w = image.size.width * scale;
    float h = image.size.height * scale;
    float x = (-CGRectGetMidX(rect) + directionX) * w + CGRectGetWidth(self.view.frame) * 0.5;
    float y = (-CGRectGetMidY(rect) + directionY) * h + CGRectGetHeight(self.view.frame) * 0.5;
    
    if (self.showWithAddtionZoom) {
        float newX = MAX(MIN(x, 0), -w + CGRectGetWidth(self.view.frame));
        float newY = MAX(MIN(y, 0), -h + CGRectGetHeight(self.view.frame));
        float addz = fabs(newX - x) + fabs(newY - y);
        scale += addz * 0.002;
        
        w = image.size.width * scale;
        h = image.size.height * scale;
        x = (-CGRectGetMidX(rect) + directionX) * w + CGRectGetWidth(self.view.frame) * 0.5;
        y = (-CGRectGetMidY(rect) + directionY) * h + CGRectGetHeight(self.view.frame) * 0.5;
    }
    
    x = MAX(MIN(x, 0), -w + CGRectGetWidth(self.view.frame));
    y = MAX(MIN(y, 0), -h + CGRectGetHeight(self.view.frame));
    
    CGRect frame = CGRectMake(x, y, w, h);
    self.imageView.frame = frame;
    self.playerView.frame = frame;
}

- (void)calculateScrollView
{
    float sizeW = self.scrollView.frame.size.width;
    float sizeH = self.scrollView.frame.size.height;
    float centerX = (self.scrollView.contentOffset.x + sizeW * 0.5) / self.scrollView.contentSize.width;
    float centerY = (self.scrollView.contentOffset.y + sizeH * 0.5) / self.scrollView.contentSize.height;
    
    UIImage *image = self.imageView.image;
    float zoomX = self.view.frame.size.width / image.size.width;
    float zoomY = self.view.frame.size.height / image.size.height;
    
    self.scrollView.minimumZoomScale = MAX(zoomX, zoomY);
    self.scrollView.maximumZoomScale = 4;
    
    if (!CGRectEqualToRect(self.frameRect, CGRectZero)) {
        centerX = CGRectGetMidX(self.frameRect);
        centerY = CGRectGetMidY(self.frameRect);
        
        float zoomX = self.view.frame.size.width / self.frameRect.size.width / image.size.width;
        float zoomY = self.view.frame.size.height / self.frameRect.size.height / image.size.height;
        float zoomScale = MAX(MIN(zoomX, zoomY), self.scrollView.minimumZoomScale);
        self.scrollView.zoomScale = zoomScale;
        
    } else if (CGPointEqualToPoint(self.scrollView.contentOffset, CGPointZero)) {
        centerX = 0.5;
        centerY = 0.5;
    }
    
    if (self.scrollView.zoomScale < self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:NO];
    }
    
    [self.scrollView layoutIfNeeded];
    [self.view layoutIfNeeded];
    
    sizeW = self.scrollView.frame.size.width;
    sizeH = self.scrollView.frame.size.height;
    centerX *= self.scrollView.contentSize.width;
    centerY *= self.scrollView.contentSize.height;
    
    CGPoint contentOffset = CGPointMake(centerX - sizeW * 0.5, centerY - sizeH * 0.5);
    contentOffset.x = MIN(MAX(0, contentOffset.x), self.scrollView.contentSize.width - self.scrollView.frame.size.width);
    contentOffset.y = MIN(MAX(0, contentOffset.y), self.scrollView.contentSize.height - self.scrollView.frame.size.height);
    [self.scrollView setContentOffset:contentOffset animated:NO];
}

- (void)saveFrame
{
    UIImage *image = self.imageView.image;
    CGRect rect = [self.view convertRect:self.view.bounds toView:self.imageBg];
    rect.origin.x /= image.size.width;
    rect.origin.y /= image.size.height;
    rect.size.width /= image.size.width;
    rect.size.height /= image.size.height;
    self.media.frameRect = [NSValue valueWithCGRect:rect];
}

- (void)clearFrame
{
    self.frameRect = CGRectZero;
}

- (void)updateFrames
{
    if (self.canEdit) {
        self.imageView.frame = [self.view convertRect:self.imageBg.bounds fromView:self.imageBg];
        self.playerView.frame = self.imageView.frame;
    }
}

- (BOOL)isHavePlayerView:(AVPlayerView *)playerView
{
    return [playerView isEqual:_playerView];
}

- (IBAction)didTapButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(storyEditorCellControllerDidSelect:)]) {
        [self.delegate storyEditorCellControllerDidSelect:self];
    }
}

#pragma mark - UIScrollView delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageBg;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.isTracking) {
        [self saveFrame];
    }
    
    [self updateFrames];
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [self saveFrame];
}

@end
