//
//  CellIdentifierCell.h
//  StorytellingMobileApp
//
//  Created by vaskov on 02.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreviewController.h"

@interface StoryCollectionCell : UICollectionViewCell
@property (nonatomic, strong, readonly) PreviewController *controller;
@property (strong, nonatomic) Story *story;
@property (nonatomic) BOOL showFullScreen;
@property (weak, nonatomic) IBOutlet UIView *titleStoryView;
@property (weak, nonatomic) IBOutlet UIImageView *gradient;

- (void)setShowFullScreen:(BOOL)showFromHomeScreenFullScreen;
- (void)setDeltaX:(CGFloat)deltaX mainCell:(BOOL)isMain right:(BOOL)isRight;

@end

