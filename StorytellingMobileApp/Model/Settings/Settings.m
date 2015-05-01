//
//  Settings.m
//  StorytellingMobileApp
//
//  Created by vaskov on 26.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "Settings.h"
#import "DataManager.h"
#import "AmazonS3Defines.h"
#import <AWSRuntime/AmazonEndpoints.h>

#define BIG_COMPRESS_OF_VIDEO_KEY @"BigCompressOfVideoKey"
#define SMALL_COMPRESS_OF_VIDEO_KEY @"SmallCompressOfVideoKey"
#define EARLY_COMPRESS_KEY @"EarlyCompreeesKey"
#define CDN_BASE_URL_KEY @"cdnBaseUrlKey"
#define BIG_IMAGE_SIZE_KEY @"BigImageSizeKey"
#define SMALL_IMAGE_SIZE_KEY @"SmallImageSizeKey"
#define CACHE_STORY_MEDIA_KEY @"CacheStoryMediaKey"
#define USER_KEY @"UserKey"
#define STORY_LAYOUT_GRID_KEY @"storyLaoutGrid"
#define AUTO_PLAY_MULTIPLE_VIDEOS_TYPE @"AutoPlayMultipleVideosType"

NSString *kUserPhotoChangedNotification = @"kUserPhotoChangedNotification";

NSArray* CDNBaseUrlOptions = nil;


@implementation Settings

+(instancetype) sharedInstance {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{   
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

+(NSArray*)cdnBaseUrlOptions
{
    static NSArray* options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
                    [AmazonEndpoints s3Endpoint:0],// US_EAST_1      = 0, us standard
                    [AmazonEndpoints s3Endpoint:1],// US_WEST_1      = 1, california
                    [AmazonEndpoints s3Endpoint:2],// EU_WEST_1      = 2, ireland
                    [AmazonEndpoints s3Endpoint:3],// AP_SOUTHEAST_1 = 3, singapore
                    [AmazonEndpoints s3Endpoint:4],// AP_NORTHEAST_1 = 4, tokyo
                    [AmazonEndpoints s3Endpoint:5],// US_WEST_2      = 5, oregon
                    [AmazonEndpoints s3Endpoint:6],// SA_EAST_1      = 6, sao paulo
                    [AmazonEndpoints s3Endpoint:7],// AP_SOUTHEAST_2 = 7, Sydney
                    CDN_PATH
                    ];
    });
    return options;
}

-(NSString *)bucketName
{
    NSUInteger index;
    index = [[self.class cdnBaseUrlOptions] indexOfObject:self.cdnBaseUrl];
    if (NSNotFound == index) {
        index = EU_WEST_1;
    }
    else if (index > 7) {
        return nil;
    }
    return [NSString stringWithFormat:@"dev.poc.storytelling.%@.myheritage.com",
                @[
                  @"us",
                  @"ca",
                  @"ie",
                  @"sg",
                  @"tk",
                  @"or",
                  @"sp",
                  @"sy",
                  ][index]];
    
}

-(instancetype) initUniqueInstance {
    
    self = [super init];
    if (self) {
        if (self.bigCompressVideoType < 0)
            self.bigCompressVideoType = CompressOfVideoType640x480;
        if (self.smallCompressVideoType < 0)
            self.smallCompressVideoType = CompressOfVideoType640x480;
        if (self.earlyCompress < 0)
            self.earlyCompress = YES;
        if (self.bigImageSizeType < 0)
            self.bigImageSizeType = ImageSizeType07MP;
        if (self.smallImageSizeType < 0)
            self.smallImageSizeType = ImageSizeType07MP;
        if (self.cacheStoryMedia < 0)
            self.cacheStoryMedia = NO;
        if (self.videosType < 0)
            self.videosType = AutoPlayMultipleVideosTypeSimultaneous;
        
        if (NSNotFound == [[self.class cdnBaseUrlOptions] indexOfObject:self.cdnBaseUrl]) {
            self.cdnBaseUrl = [self.class cdnBaseUrlOptions][EU_WEST_1];
        }
        
        if (self.myUser == nil){
            __block User *user = nil;
            [[DATA_MANAGER managedObjectContext] performBlockAndWait:^{
                user = [DATA_MANAGER addUser:^(User *user) {
                    user.name = @"";
                    NSURL *url = [[NSBundle mainBundle] URLForResource:@"photoImage" withExtension:@"png"];
                    user.photo = url.absoluteString;
                } inContext:DATA_MANAGER.managedObjectContext];
            }];
            [DATA_MANAGER saveContext];
            self.myUser = user;
        }
    }
    
    return self;
}

#pragma mark - Properties

- (void)setBigCompressVideoType:(CompressOfVideoType)bigCompressVideoType
{
    [[NSUserDefaults standardUserDefaults] setObject:@(bigCompressVideoType) forKey:BIG_COMPRESS_OF_VIDEO_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CompressOfVideoType)bigCompressVideoType
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:BIG_COMPRESS_OF_VIDEO_KEY];
    return number == nil ? -1 : [number integerValue];
}

- (void)setSmallCompressVideoType:(CompressOfVideoType)smallCompressVideoType
{
    [[NSUserDefaults standardUserDefaults] setObject:@(smallCompressVideoType) forKey:SMALL_COMPRESS_OF_VIDEO_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CompressOfVideoType)smallCompressVideoType
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:SMALL_COMPRESS_OF_VIDEO_KEY];
    return number == nil ? -1 : [number integerValue];
}

- (void)setEarlyCompress:(BOOL)earlyCompress
{
    [[NSUserDefaults standardUserDefaults] setObject:@(earlyCompress) forKey:EARLY_COMPRESS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)earlyCompress
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:EARLY_COMPRESS_KEY];
    return number == nil ? -1 : [number integerValue];
}

- (void)setBigImageSizeType:(ImageSizeType)bigImageSizeType
{
    [[NSUserDefaults standardUserDefaults] setObject:@(bigImageSizeType) forKey:BIG_IMAGE_SIZE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (ImageSizeType)bigImageSizeType
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:BIG_IMAGE_SIZE_KEY];
    return number == nil ? -1 : [number integerValue];
}

- (void)setSmallImageSizeType:(ImageSizeType)smallImageSizeType
{
    [[NSUserDefaults standardUserDefaults] setObject:@(smallImageSizeType) forKey:SMALL_IMAGE_SIZE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (ImageSizeType)smallImageSizeType
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:SMALL_IMAGE_SIZE_KEY];
    return number == nil ? -1 : [number integerValue];
}

- (void)setCacheStoryMedia:(BOOL)cacheStoryMedia
{
    [[NSUserDefaults standardUserDefaults] setObject:@(cacheStoryMedia) forKey:CACHE_STORY_MEDIA_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)cacheStoryMedia
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:CACHE_STORY_MEDIA_KEY];
    return number == nil ? -1 : [number boolValue];
}

-(void)setCdnBaseUrl:(NSString *)cdnBaseUrl
{
    if (NSNotFound == [[self.class cdnBaseUrlOptions] indexOfObject:cdnBaseUrl])
    {
        cdnBaseUrl = [self.class cdnBaseUrlOptions][EU_WEST_1];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:cdnBaseUrl forKey:CDN_BASE_URL_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)cdnBaseUrl
{
    NSString* url = [[NSUserDefaults standardUserDefaults] objectForKey:CDN_BASE_URL_KEY];
    if (NSNotFound == [[self.class cdnBaseUrlOptions] indexOfObject:url])
    {
        url = [self.class cdnBaseUrlOptions][EU_WEST_1];
        [[NSUserDefaults standardUserDefaults] setObject:url forKey:CDN_BASE_URL_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return url;
}

- (void)setMyUser:(User *)myUser
{
    NSURL *url = [myUser.objectID URIRepresentation];
    [[NSUserDefaults standardUserDefaults] setURL:url forKey:USER_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (User *)myUser
{
    NSURL *url = [[NSUserDefaults standardUserDefaults] URLForKey:USER_KEY];
    return url == nil ? nil : [DATA_MANAGER userWithUriRepresentation:url inContext:DATA_MANAGER.managedObjectContext];
}

-(void)setStoryLayoutGrid:(BOOL)storyLayoutGrid
{
    [[NSUserDefaults standardUserDefaults] setObject:@(storyLayoutGrid) forKey:STORY_LAYOUT_GRID_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(BOOL)storyLayoutGrid
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:STORY_LAYOUT_GRID_KEY];
    return number == nil ? -1 : [number boolValue];
}

- (void)setVideosType:(AutoPlayMultipleVideosType)videosType
{
    [[NSUserDefaults standardUserDefaults] setObject:@(videosType) forKey:AUTO_PLAY_MULTIPLE_VIDEOS_TYPE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (AutoPlayMultipleVideosType)videosType
{
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:AUTO_PLAY_MULTIPLE_VIDEOS_TYPE];
    return number == nil ? -1 : [number integerValue];
}

@end
