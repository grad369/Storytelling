//
//  AmazonS3Download.h
//  StorytellingMobileApp
//
//  Created by vaskov on 14.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Story;

@interface AmazonS3Download : NSOperation
- (instancetype)initWithIdStory:(NSString *)idStory;
@end
