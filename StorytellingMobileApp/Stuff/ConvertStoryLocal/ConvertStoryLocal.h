//
//  ConvertStoryLocal.h
//  StorytellingMobileApp
//
//  Created by vaskov on 09.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Model.h"

@interface ConvertStoryLocal : NSOperation
@property (nonatomic, copy) void(^progressBlock)(float progress); // from 0 to 1

- (instancetype)initWithStory:(Story *)story;

@end
