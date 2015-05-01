//
//  DataManager.m
//  StorytellingMobileApp
//
//  Created by vaskov on 27.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "DataManager.h"

@interface DataManager ()
@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSArray *stories;
@end


@implementation DataManager

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

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
        return _managedObjectContext;
   
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:self.coordinator];
    
    return _managedObjectContext;
}

- (NSManagedObjectModel *)model
{
    if (_model != nil)
        return _model;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _model;
}

- (NSURL *)storeURL
{
    NSString *pathToDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [[NSURL fileURLWithPath:pathToDocuments] URLByAppendingPathComponent:@"Data.sqlite"];
}

- (NSPersistentStoreCoordinator *)coordinator
{
    if (_coordinator != nil)
        return _coordinator;
    
    NSURL *storeURL = [self storeURL];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    NSError *error = nil;
    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    if (![self.coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _coordinator;
}

- (void)saveContext
{
    __block NSError *error = nil;
    
    if (_managedObjectContext == nil)
        return;
    
    [_managedObjectContext performBlockAndWait:^{
        if ([_managedObjectContext hasChanges]) {
            [_managedObjectContext save:&error];
            if (error != nil) {
                NSLog(@"%@ === %@", [error localizedDescription], [error userInfo]);
                abort();
            }
        }
    }];
}

#pragma mark - Publics

- (Story *)addStory:(void(^)(Story *story))initializerBlock inContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Story class])
                                              inManagedObjectContext:context];
    Story *story = [[Story alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    story.id = [[NSUUID UUID] UUIDString];
    story.date = [NSDate date];
    initializerBlock(story);
    
    return story;
}

- (User *)addUser:(void(^)(User *user))initializerBlock inContext:(NSManagedObjectContext*)context
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([User class])
                                              inManagedObjectContext:context];
    User *user = [[User alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    initializerBlock(user);
    
    return user;
}

- (Media *)addMedia:(void(^)(Media *media))initializerBlock inContext:(NSManagedObjectContext*)context
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Media class])
                                              inManagedObjectContext:context];
    Media *media = [[Media alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    initializerBlock(media);
    
    return media;
}

- (Story *)storyWithId:(NSString *)id inContext:(NSManagedObjectContext*)context
{
    NSError *error = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", id];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Story class])
                                              inManagedObjectContext:context];
    NSFetchRequest * request = [NSFetchRequest new];
    [request setEntity:entity];
    [request setPredicate:predicate];
    
    NSArray *result = [context executeFetchRequest:request error:&error];
    
    if (error)
    {
        NSLog(@"Load made mistake: %@", [error userInfo]);
        return nil;
    }
    
    return result.firstObject;
}

- (User *)userWithUriRepresentation:(NSURL *)url inContext:(NSManagedObjectContext*)context
{
    NSError *error;
    NSManagedObjectID *objectId = [self.coordinator managedObjectIDForURIRepresentation:url];
    User *user = (User*)[context existingObjectWithID:objectId error:&error];
    if (error != nil) {
        NSLog(@"%@", [error description]);
        abort();
    }
    return user;
}

@end
