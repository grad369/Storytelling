//
//  ALAssetWrapper.m
//  StorytellingMobileApp
//
//  Created by Леонід on 19.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "ALAssetWrapper.h"

@interface ALAssetWrapper  ()

@property (nonatomic, strong) ALAsset* asset;
@end

@implementation ALAssetWrapper

+(instancetype)wrapperWithAsset:(ALAsset*)asset
{
    ALAssetWrapper* aw = [ALAssetWrapper new];
    if (aw)
        aw.asset = asset;
    return aw;
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:self.class]) {
        ALAssetWrapper* other = (ALAssetWrapper*)object;
        return [self.asset.defaultRepresentation.url isEqual:other.asset.defaultRepresentation.url];
    }
    return [super isEqual:object];
}

-(NSUInteger)hash
{
    return self.asset.defaultRepresentation.url.hash;
}

@end
