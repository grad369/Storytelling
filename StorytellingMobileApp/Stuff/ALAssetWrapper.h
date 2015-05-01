//
//  ALAssetWrapper.h
//  StorytellingMobileApp
//
//  Created by Леонід on 19.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetWrapper : NSObject
@property (nonatomic, strong, readonly) ALAsset* asset;
+(instancetype)wrapperWithAsset:(ALAsset*)asset;
@end
