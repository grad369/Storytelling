//
//  Media.h
//  StorytellingMobileApp
//
//  Created by vaskov on 28.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Story;

@interface Media : NSManagedObject

@property (nonatomic, retain) id frameRect;
@property (nonatomic, retain) NSString * largeImageURL;
@property (nonatomic, retain) NSString * largeVideoURL;
@property (nonatomic, retain) NSString * smallImageURL;
@property (nonatomic, retain) NSString * smallVideoURL;
@property (nonatomic, retain) Story *story;

@end

@interface FrameRect : NSValueTransformer
@end