//
//  Settings.h
//  StorytellingMobileApp
//
//  Created by vaskov on 26.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SingletonProtocol.h"
#import "User.h"

#define SETTINGS [Settings sharedInstance]

typedef NS_ENUM(NSInteger, CompressOfVideoType){
    CompressOfVideoTypeLow        = 0,
    CompressOfVideoTypeMedium     = 1,    
    CompressOfVideoTypeHigh       = 2, 
    CompressOfVideoType640x480    = 3,
    CompressOfVideoType960x540    = 4,
    CompressOfVideoType1280x720   = 5
};

typedef NS_ENUM(NSInteger, ImageSizeType){
    ImageSizeType03MP       = 0,
    ImageSizeType07MP       = 1,
    ImageSizeType1MP        = 2,
    ImageSizeType2MP        = 3
};

typedef NS_ENUM(NSInteger, AutoPlayMultipleVideosType){
    AutoPlayMultipleVideosTypeSimultaneous,
    AutoPlayMultipleVideosTypeSynchronized
};

@interface Settings : NSObject <SingletonProtocol>
@property (nonatomic, assign) CompressOfVideoType bigCompressVideoType;
@property (nonatomic, assign) CompressOfVideoType smallCompressVideoType;
@property (nonatomic, assign) BOOL earlyCompress;
@property (nonatomic, assign) ImageSizeType bigImageSizeType;
@property (nonatomic, assign) ImageSizeType smallImageSizeType;
@property (nonatomic, assign) BOOL cacheStoryMedia;
@property (nonatomic, copy)   NSString *cdnBaseUrl;
@property (nonatomic, readonly, strong) NSString* bucketName;
@property (nonatomic, assign) BOOL storyLayoutGrid;
@property (nonatomic, assign) AutoPlayMultipleVideosType videosType;

@property (nonatomic, strong) User *myUser;

+(NSArray*)cdnBaseUrlOptions;
@end


extern NSString *kUserPhotoChangedNotification;
