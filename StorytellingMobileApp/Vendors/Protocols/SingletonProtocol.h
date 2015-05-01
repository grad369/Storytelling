//
//  SingletonProtocol.h
//  LFT_TCKT
//
//  Created by vaskov on 17.11.13.
//  Copyright (c) 2013 qarea. All rights reserved.
//

@protocol SingletonProtocol <NSObject>

+ (instancetype)sharedInstance;

+ (instancetype)alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
- (instancetype)init __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype)new __attribute__((unavailable("new not available, call sharedInstance instead")));

@end

// implementation

/*
 + (instancetype) sharedInstance {
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
    shared = [[super alloc] initUniqueInstance];
    });
    return shared;
 }
 
 - (instancetype) initUniqueInstance {
    self = [super init];
    if (self) {
    }
    return self;
 }
 */