//
//  Story+Extra.m
//  StorytellingMobileApp
//
//  Created by Leonid Usov on 16.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "Story+Extra.h"
#import "DataManager.h"
#import "Settings.h"

@implementation Story (Extra)

-(NSURL *)shareURL
{
    if ([self.shared boolValue]) {
        NSURL* url = [[NSURL alloc] initWithScheme:@"mh-story" host:self.id path:@"/"];
        return url;
    }
    return nil;
}

+ (void)firstInitStories
{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"DefaultStories" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *plistPath = [bundle pathForResource:@"DefaultStories" ofType:@"plist"];
    NSArray *stories = [NSArray arrayWithContentsOfFile:plistPath];
    for (NSDictionary *storyDict in stories) {
        Story *story = [DATA_MANAGER addStory:^(Story *story) {
        } inContext:DATA_MANAGER.managedObjectContext];
        
        story.id = storyDict[@"storyId"];
        story.title = storyDict[@"title"];
        story.text = storyDict[@"text"];
        story.layoutType = storyDict[@"layoutType"];
        story.preloaded = @YES;
        story.shared = @YES;
        
        NSMutableOrderedSet *set = [[NSMutableOrderedSet alloc] init];
        NSArray *medias = storyDict[@"media"];
        
        for (NSDictionary *mediaDict in medias) {
            Media *media = [DATA_MANAGER addMedia:^(Media *media) {
            } inContext:DATA_MANAGER.managedObjectContext];
            NSDictionary *frameDict = mediaDict[@"frameRect"];
            CGRect frame = CGRectMake([frameDict[@"x"] floatValue], [frameDict[@"y"] floatValue], [frameDict[@"w"] floatValue], [frameDict[@"h"] floatValue]);
            media.frameRect = [NSValue valueWithCGRect:frame];
            NSString *image = mediaDict[@"image"];
            media.largeImageURL = [bundle pathForResource:image ofType:@"png"];
            NSString *video = mediaDict[@"video"];
            media.largeVideoURL = video.length == 0 ? nil : [bundle pathForResource:video ofType:@"mp4"];
            [set addObject:media];
        }
        
        story.media = set;
        
        NSDictionary *userDict = storyDict[@"user"];
        User *user = [DATA_MANAGER addUser:^(User *user) {
        } inContext:DATA_MANAGER.managedObjectContext];
        NSString *image = userDict[@"photo"];
        user.photo = [bundle pathForResource:image ofType:@"png"];
        user.name = userDict[@"name"];
        story.user = user;
    }
    [DATA_MANAGER saveContext];
}

@end
