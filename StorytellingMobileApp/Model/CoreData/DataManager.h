//
//  DataManager.h
//  StorytellingMobileApp
//
//  Created by vaskov on 27.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SingletonProtocol.h"
#import "Model.h"

#define DATA_MANAGER [DataManager sharedInstance]

@interface DataManager : NSObject <SingletonProtocol>

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
- (void)saveContext;
- (NSURL *)storeURL;

- (Story *)addStory:(void(^)(Story *story))initializerBlock inContext:(NSManagedObjectContext*)context;      // fill object exception id
- (User *)addUser:(void(^)(User *user))initializerBlock inContext:(NSManagedObjectContext*)context;
- (Media *)addMedia:(void(^)(Media *media))initializerBlock inContext:(NSManagedObjectContext*)context;

- (Story *)storyWithId:(NSString *)id inContext:(NSManagedObjectContext*)context;
- (User *)userWithUriRepresentation:(NSURL *)url inContext:(NSManagedObjectContext*)context;

@end
