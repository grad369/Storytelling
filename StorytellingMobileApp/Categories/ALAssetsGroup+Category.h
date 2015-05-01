//
//  ALAssetsGroup+Category.h
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 14.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetsGroup (Category)

- (NSArray *)assetsInGroupAscending:(BOOL)ascending;

@end
