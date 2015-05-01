//
//  ALAssetsLibrary+Category.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 27.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsGroup+Category.h"

@interface ALAssetsLibrary (Category)

+ (ALAssetsLibrary *)sharedLibrary;

+ (void)assetWithPath:(NSString *)path
               result:(void(^)(ALAsset *asset))resultBlock
         failureBlock:(void(^)(NSError *error))errorBlock
                 wait:(BOOL)isWait;


@end
