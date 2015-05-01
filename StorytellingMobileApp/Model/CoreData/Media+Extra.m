//
//  Media+Extra.m
//  StorytellingMobileApp
//
//  Created by Leonid Usov on 28.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "Media+Extra.h"
#import <objc/runtime.h>

static const char LargeAssetTag = 0;
static const void* LargeAssetKey = &LargeAssetTag;

@implementation Media (Extra)

-(ALAsset *)largeAsset
{
    return (ALAsset*)objc_getAssociatedObject(self, LargeAssetKey);
}

-(void)setLargeAsset:(ALAsset *)asset
{
    NSString *url = [asset.defaultRepresentation.url absoluteString];
    self.largeImageURL = url;
    //media.smallImageURL = url;
    BOOL idVideo = [[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo];
    if (idVideo) {
        self.largeVideoURL = url;
        //self.smallVideoURL = url;
    }
    
    objc_setAssociatedObject(self, LargeAssetKey, asset, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
