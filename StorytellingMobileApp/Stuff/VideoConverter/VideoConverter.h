//
//  VideoConverter.h
//  StorytellingMobileApp
//
//  Created by vaskov on 25.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Settings.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef void(^ProgressBlock)(NSString* key, CGFloat progress); // progress from 0 to 1

@interface VideoConverter : NSObject

- (NSString *)convertVideo:(ALAsset* )videoAsset
                outputName:(NSString *)fileName
                    toType:(CompressOfVideoType)type
                  progress:(ProgressBlock)progressBlock; // return key ExportSession


- (void)cancelSessionWithKey:(NSString *)key;
- (void)cancelAllSessions;
- (void)waitUntilSessionWithKey:(NSString *)key isFinished:(AVAssetExportSessionStatus *)status;

@end
