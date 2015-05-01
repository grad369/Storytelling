//
//  CellIdentifierCell.m
//  StorytellingMobileApp
//
//  Created by vaskov on 02.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "StoryCollectionCell.h"
#import "UIView+Helpers.h"
#import "UIImageView+Circle.h"
#import "Model.h"
#import "Cache.h"
#import "StoryLayoutController.h"

#define SHIFT 160.0f

@interface StoryCollectionCell ()
@property (nonatomic, strong) PreviewController *controller;
@property (weak, nonatomic) IBOutlet UIImageView *myPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleStoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *myNameLabel;
@property (weak, nonatomic) IBOutlet UIView *touchesIntercept;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleCenterConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameCenterConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photoCenterConstraint;
@end

@implementation StoryCollectionCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.controller = [[PreviewController alloc] initWithNibName:@"PreviewController" bundle:nil];
        self.controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.controller.view.frame = self.bounds;
        [self.contentView insertSubview:_controller.view atIndex:0];
        self.controller.showFromHomeScreen = YES;
        self.controller.showFromHomeScreenFullScreen = NO;
        
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self.controller.layoutController action:@selector(handleLongPressGesture:)];
        [self addGestureRecognizer:recognizer];
    }
    return self;
}

- (void)setStory:(Story *)story
{
    _story = story;
    
    if (story == nil)
        return;
    
    self.controller.story = story;
    _titleStoryLabel.text = [story.title uppercaseString];
    _myNameLabel.text = story.user.name;
    _myPhotoImageView.hidden = YES;
    [Cache imageForKey:story.user.photo fullResolutionImage:NO block:^(TMCache *cache, NSString *key, id object) {
        _myPhotoImageView.image = object;
        _myPhotoImageView.hidden = NO;
        _myPhotoImageView.isCircle = YES;
    }];
}

- (void)setShowFullScreen:(BOOL)showFromHomeScreenFullScreen
{
    _showFullScreen = showFromHomeScreenFullScreen;
    self.touchesIntercept.userInteractionEnabled = !showFromHomeScreenFullScreen;
    self.titleTopConstraint.constant = showFromHomeScreenFullScreen ? (CGRectGetHeight(self.frame) + 10) : 235;
    [self layoutIfNeeded];
    
    self.gradient.alpha = 1 - showFromHomeScreenFullScreen;
    [self.controller setShowFromHomeScreenFullScreen:showFromHomeScreenFullScreen];
}

- (void)setDeltaX:(CGFloat)deltaX mainCell:(BOOL)isMain right:(BOOL)isRight
{
    CGFloat(^constantBlockMain)(CGFloat stay, CGFloat k) = ^CGFloat(CGFloat stay, CGFloat k){
        CGFloat temp, shift = isRight ? -deltaX : SHIFT - deltaX;
        
        if (abs(shift) < stay)
            temp = isRight ? -k * deltaX : k * (SHIFT - deltaX);
        else
            temp = isRight ? -k * stay : k * stay;
        
        if (deltaX == 0) temp = 0;
        
        return temp;
    };
    
    CGFloat(^constantBlock)(CGFloat stay) = ^CGFloat(CGFloat stay){
        
        CGFloat temp, shift = isRight ? SHIFT-deltaX : -deltaX;
        
        if (abs(shift) > stay)
            temp = stay;
        else
            temp = isRight ? (SHIFT - deltaX) : deltaX;
        
        if (deltaX == 0) temp = 0;
        
        return temp;
    };
    
    CGFloat(^alphaBlock)(CGFloat limitMin, CGFloat limitMax) = ^CGFloat(CGFloat limitMin, CGFloat limitMax){
        
        CGFloat alpha, delta;
        BOOL temp = isMain ? isRight : !isRight;
        
        if (temp){
            delta = limitMax - limitMin;
            alpha = 1 - ((abs(deltaX)-limitMin)/delta);
            if (abs(deltaX)<limitMin) alpha = 1;
            if (abs(deltaX)>limitMax) alpha = 0;
        }
        else {
            CGFloat shift = abs(SHIFT - deltaX);
            alpha = limitMax > abs(shift) ? abs((limitMax-abs(shift)))/limitMax : 0;
            if (abs(shift)<limitMin) alpha = 1;
        }
        
        if (deltaX==0)  alpha = 1;
        
        return alpha;
    };
    
    if (isMain) {
        _titleCenterConstraint.constant = constantBlockMain(40, 1.0f);
        _nameCenterConstraint.constant = constantBlockMain(50, 1.6f);
        
        [self layoutIfNeeded];
        
        _myPhotoImageView.alpha = alphaBlock(20, 55);
        _titleStoryLabel.alpha = alphaBlock(20, 55);
        _myNameLabel.alpha = alphaBlock(45, 63);
    }
    else {
        _photoCenterConstraint.constant = constantBlock(40);
        _titleCenterConstraint.constant = 0;
        _nameCenterConstraint.constant = -constantBlock(40);
        
        [self layoutIfNeeded];
        
        _myPhotoImageView.alpha = alphaBlock(20, 55);
        _titleStoryLabel.alpha = alphaBlock(20, 55);
        _myNameLabel.alpha = alphaBlock(10, 55);
    }
}

@end
