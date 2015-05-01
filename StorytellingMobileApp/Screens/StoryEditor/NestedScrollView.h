//
//  NestedScrollView.h
//  StorytellingMobileApp
//
//  Created by Leonid Usov on 09.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NestedScrollView : UIScrollView
@property (strong, nonatomic) UIView* noTouchCancelInThisView;
@end
