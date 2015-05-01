//
//  ALAssetsLibrary+Category.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 27.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "ALAssetsLibrary+Category.h"

@implementation ALAssetsLibrary (Category)

+ (ALAssetsLibrary *)sharedLibrary
{
    static ALAssetsLibrary *library = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    
    return library;
}

+ (void)assetWithPath:(NSString *)path
               result:(void(^)(ALAsset *asset))resultBlock
         failureBlock:(void(^)(NSError *error))errorBlock
                 wait:(BOOL)isWait
{
    NSCondition *condition = [NSCondition new];
    __block BOOL ready = NO;
    
    void(^getReady)() = ^{
        [condition lock];
        ready = YES;
        [condition signal];
        [condition unlock];
    };
   
    
    
    ALAssetsLibrary *assetLibrary = [ALAssetsLibrary sharedLibrary];
    [assetLibrary assetForURL:[NSURL URLWithString:path]
                  resultBlock:^(ALAsset *asset){
                      resultBlock(asset);
                      if (isWait)
                          getReady();
                  }
                 failureBlock:^(NSError *error) {
                     errorBlock(error);
                     NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                     if (isWait)
                         getReady();
                 }];
    
    if (isWait) {
        [condition lock];
        while (!ready) {
            [condition wait];
        }
        [condition unlock];
    }
}

@end
