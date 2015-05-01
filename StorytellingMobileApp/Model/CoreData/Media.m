//
//  Media.m
//  StorytellingMobileApp
//
//  Created by vaskov on 28.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "Media.h"
#import "Story.h"


@implementation Media

@dynamic frameRect;
@dynamic largeImageURL;
@dynamic largeVideoURL;
@dynamic smallImageURL;
@dynamic smallVideoURL;
@dynamic story;

@end


@implementation FrameRect

+ (Class)transformedValueClass
{
    return [NSValue class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end
