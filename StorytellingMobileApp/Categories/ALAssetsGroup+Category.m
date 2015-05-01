//
//  ALAssetsGroup+Category.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 14.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "ALAssetsGroup+Category.h"

@implementation ALAssetsGroup (Category)

- (NSArray *)assetsInGroupAscending:(BOOL)ascending
{
    NSMutableArray *array = [NSMutableArray array];
    [self enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            [array addObject:result];
        }
    }];
    
    if (!ascending) {
        [array sortUsingComparator:^NSComparisonResult(ALAsset *obj1, ALAsset *obj2) {
            NSDate *date1 = [obj1 valueForProperty:ALAssetPropertyDate];
            NSDate *date2 = [obj2 valueForProperty:ALAssetPropertyDate];
            return [date2 compare:date1];
        }];
    }
    return array;
}

@end
