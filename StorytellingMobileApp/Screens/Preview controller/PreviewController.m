//
//  PreviewController.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 09.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "PreviewController.h"
#import "DataManager.h"
#import "StoryLayoutController.h"
#import "UIImageView+Circle.h"
#import "UIView+Helpers.h"
#import "Story+Extra.h"
#import "Cache.h"
#import "StoryCreatedController.h"
#import "AmazonS3Download.h"
#import "AmazonS3Upload.h"
#import "ConvertStoryLocal.h"

#import "NSObject+MTKObserving.h"
#import "keypath.h"

NSString * kDidUploadStoryNotification = @"kDidUploadStoryNotification";


@interface PreviewController () <StoryCreatedControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *layoutBgView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userPhoto;
@property (weak, nonatomic) IBOutlet UILabel *storyTitle;
@property (weak, nonatomic) IBOutlet UILabel *storyText;
@property (weak, nonatomic) IBOutlet UIView *textBg;
@property (weak, nonatomic) IBOutlet UIView *sharingBg;
@property (weak, nonatomic) IBOutlet UIView *sharingProgressView;
@property (weak, nonatomic) IBOutlet UILabel *sharingLabel;
@property (weak, nonatomic) IBOutlet UIView *navigationBg;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressConstraint;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *layoutBgHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *greyViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *greyViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *darkView;
@property (weak, nonatomic) IBOutlet UIView *grayView;

@property (strong, nonatomic) StoryLayoutController *layoutController;

@property (strong, nonatomic) NSManagedObjectContext* processingContext;

@end

@implementation PreviewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.userPhoto setCircle:YES];
    self.userPhoto.layer.borderWidth = 2.0f;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
    
    self.layoutController = [[StoryLayoutController alloc] initWithNibName:@"StoryLayoutController" bundle:nil];
    self.layoutController.view.autoresizingMask = UIViewAutoresizingNone;
    self.layoutController.showVideo = YES;
    self.layoutController.showFullScreenPreview = YES;
    self.layoutController.story = self.story;
    [self.layoutBgView insertSubview:self.layoutController.view belowSubview:self.sharingBg];
    [self addChildViewController:self.layoutController];
    [self updateViews];
    
    if (!self.showFromHomeScreen) {
        [self.shareButton setTitle:@"Create" forState:UIControlStateNormal];
    }
    
    __weak typeof (self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
         [weakSelf.presentingViewController dismissViewControllerAnimated:NO completion:nil];
         [weakSelf didTapCloseButton:nil];
    }];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self layout];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat constant = self.showFromHomeScreen || self.showFromEditor ? 0 : 10;
    self.contentLeadingConstraint.constant = constant;
    self.contentTrailingConstraint.constant = constant;
    self.greyViewBottomConstraint.constant = constant;
    self.navigationTopConstraint.constant = (self.showFromHomeScreen && !self.showFromHomeScreenFullScreen) || self.showFromEditor ? - CGRectGetHeight(self.navigationBg.frame) : 0;
    
    constant = 300;
    if (self.showFromEditor) {
        constant = 318;
    }
    if (self.showFromHomeScreen && !self.showFromHomeScreenFullScreen) {
        constant = 360;
    }
    
    self.layoutBgHeightConstraint.constant = constant;
    self.navigationBg.hidden = self.showFromHomeScreen || self.showFromEditor;
    if (!self.showFromHomeScreen) {
        [self.view removeConstraint:self.greyViewTopConstraint];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.layoutBgView setNeedsLayout];
    [self.layoutBgView layoutIfNeeded];
    self.layoutController.view.frame = self.layoutBgView.bounds;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (IBAction)didTapCloseButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(previewControllerDidTapClose:)]) {
        [self.delegate previewControllerDidTapClose:self];
    }
}

- (IBAction)didTapShareButton:(UIButton *)sender
{
    if ([self.story.shared boolValue]) {
        NSURL* shareURL = self.story.shareURL;
        [self showActivityControllerWithUrl:shareURL completion:nil];
    } else {
        self.shareButton.hidden = YES;
        self.cancelButton.hidden = NO;
        [self.view layoutIfNeeded];
        [self uploadStory];
    }
}

- (IBAction)didTapCancelButton:(id)sender
{
    self.cancelButton.enabled = NO;
    [self.processingQueue cancelAllOperations];
    // for the case when it was passed
    [self.convertOperation cancel];
}

- (void)setStory:(Story *)story
{
    _story = story;
    
    if (self.isViewLoaded) {
        self.layoutController.story = self.story;
        [self updateViews];
    }
}

- (void)updateViews
{
    self.userPhoto.hidden = self.story.user.photo == nil;
    [Cache imageForKey:self.story.user.photo fullResolutionImage:NO block:^(TMCache *cache, NSString *key, id object) {
        self.userPhoto.image = object;
    }];
    
    self.userNameLabel.text = self.story.user.name;
    self.storyTitle.text = self.story.title;
    self.storyText.text = self.story.text;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateLabel.text = [formatter stringFromDate:self.story.date];
    
    self.textBg.hidden  = self.showFromEditor;
    self.scrollView.scrollEnabled = !self.showFromEditor;
    
    self.layoutController.showFullScreenPreview = !self.showFromEditor;
    self.darkView.hidden = self.showFromHomeScreen || self.showFromEditor;
}

- (void)layout
{
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)setShowFromHomeScreen:(BOOL)showFromHomeScreen
{
    _showFromHomeScreen = showFromHomeScreen;
    self.layoutController.showZoomAnimation = showFromHomeScreen;
    [self layout];
}

- (void)setShowFromHomeScreenFullScreen:(BOOL)showFromHomeScreenFullScreen
{
    if (!self.showFromHomeScreen) {
        return;
    }
    
    _showFromHomeScreenFullScreen = showFromHomeScreenFullScreen;
    self.view.userInteractionEnabled = showFromHomeScreenFullScreen;
    
    [self layout];
    self.scrollView.contentOffset = CGPointZero;
    self.textBg.alpha = showFromHomeScreenFullScreen;
    [self.layoutController setShowOnlyFirst:!showFromHomeScreenFullScreen];
}


#pragma mark - Uploading

- (void)uploadStory
{
    self.layoutController.view.userInteractionEnabled = NO;
    self.sharingBg.hidden = NO;
    self.sharingBg.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.closeButton.alpha = 0;
        self.sharingBg.alpha = 1;
    }];
    
    [self.story.managedObjectContext save:nil];
    [DATA_MANAGER saveContext];
    
    self.processingQueue = [NSOperationQueue new];
    
    AmazonS3Upload *upload;
    
    if (nil == self.convertOperation || self.convertOperation.isCancelled) {
        self.convertOperation = [[ConvertStoryLocal alloc] initWithStory:self.story];
        [self.processingQueue addOperation:self.convertOperation];
    }
    
    upload = [[AmazonS3Upload alloc] initWithStory:self.story];
    [upload addDependency:self.convertOperation];
    
    [self.processingQueue addOperation:upload];
    
    __weak typeof (self)weakSelf = self;
    
    void(^progressBlock)(float progress) = ^(float progress) {
        weakSelf.progressConstraint.constant = (1 - progress) * CGRectGetWidth(weakSelf.sharingProgressView.frame);
    };
    
    self.convertOperation.progressBlock = progressBlock;
    upload.progressBlock = progressBlock;
    
    [self observeObject:upload property:@keypath(upload.isExecuting) withBlock:^(__typeof(self) self, id object, id old, id newVal) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* text = nil;
            if ([newVal boolValue]) {
                text = @"UPLOADING...";
            }
            else {
                if (weakSelf.convertOperation.isExecuting) {
                    text = @"CREATING...";
                }
                else {
                    text = @"COMPLETED";
                }
                
            }
            weakSelf.sharingLabel.text = text;
            weakSelf.progressConstraint.constant = CGRectGetWidth(weakSelf.sharingProgressView.frame);
        });
    }];
    
    [upload setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.story.managedObjectContext save:nil];
            [DATA_MANAGER saveContext];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidUploadStoryNotification object:nil];
            self.modalPresentationStyle = UIModalPresentationFullScreen;
            self.transitioningDelegate = nil;
            
            NSURL* shareURL = self.story.shareURL;
            if (nil == shareURL) {
                self.shareButton.hidden = NO;
                self.cancelButton.hidden = YES;
                self.cancelButton.enabled = YES;
            }
            else {
                StoryCreatedController *controller = [[StoryCreatedController alloc] initWithNibName:@"StoryCreatedController" bundle:nil];
                controller.delegate = self;
                [self presentViewController:controller animated:YES completion:nil];
                
                if ([self.delegate respondsToSelector:@selector(previewControllerDidTapShare:)]) {
                    [self.delegate previewControllerDidTapShare:self];
                }
            }
            
            [UIView animateWithDuration:0.3 animations:^{
                self.sharingBg.alpha = 0;
                self.closeButton.alpha = 1;
            } completion:^(BOOL finished) {
            }];
        });
    }];
}

- (void)showActivityControllerWithUrl:(NSURL *)url completion:(void(^)())completion
{
    [self showActivityControllerWithUrl:url topController:self completion:completion];
}

- (void)showActivityControllerWithUrl:(NSURL *)url topController:(UIViewController *)controller completion:(void(^)())completion
{
    UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[
                                         UIActivityTypeAssignToContact,
                                         UIActivityTypeSaveToCameraRoll,
                                         UIActivityTypeAddToReadingList,
                                         UIActivityTypePostToFlickr,
                                         UIActivityTypePostToVimeo,
                                         UIActivityTypePostToTencentWeibo,
                                         ];
    
    [activityVC setCompletionHandler:^(NSString *activityType, BOOL completed){
        if (completion) {
            completion();
        }
    }];
    
    [controller presentViewController:activityVC animated:YES completion:nil];
}

#pragma mark - StoryCreatedControllerDelegate

- (void)storyCreatedControllerDidTapDoneButton:(StoryCreatedController *)controller
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)storyCreatedControllerDidTapShareButton:(StoryCreatedController *)controller
{
    NSURL* shareURL = self.story.shareURL;
    [self showActivityControllerWithUrl:shareURL topController:controller completion:^{
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
