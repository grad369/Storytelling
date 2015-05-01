//
//  AmazonS3Download.m
//  StorytellingMobileApp
//
//  Created by vaskov on 14.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "AmazonS3Download.h"
#import "AmazonS3Defines.h"
#import "DataManager.h"
#import "Settings.h"

@interface AmazonS3Download () <AmazonServiceRequestDelegate>
@property (nonatomic, strong) AmazonS3Client *client;
@property (nonatomic, strong) S3TransferManager *transferManager;
@property (nonatomic, strong) NSString* storyShareID;
@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) NSManagedObjectContext* childContext;
@property (nonatomic, copy) NSString *remotePath;
@end

@implementation AmazonS3Download

- (instancetype)initWithIdStory:(NSString *)idStory
{
    self = [super init];
    if (self) {
        self.storyShareID = idStory;
        
        if ([DATA_MANAGER storyWithId:idStory inContext:[DATA_MANAGER managedObjectContext]]) {
            // already downloaded, do nothing
            [self cancel];
        }
        else {
            
            NSString *remotePath = [NSString stringWithFormat:@"%@%@/content.json", SETTINGS.cdnBaseUrl, idStory];
            [self initializeWithRemoteContentPath:remotePath];
        }
    }
    return self;
}

- (void)initializeWithRemoteContentPath:(NSString *)remotePath
{
    
        self.remotePath = remotePath;
        self.client = [[AmazonS3Client alloc]
                       initWithAccessKey:ACCESS_KEY
                       withSecretKey:SECRET_KEY];
    
        _client.endpoint = SETTINGS.cdnBaseUrl;
        
        self.transferManager = [S3TransferManager new];
        self.transferManager.s3 = _client;
        self.transferManager.delegate = self;
    
}

- (void)main
{
    
    
    self.childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    self.childContext.parentContext = [DATA_MANAGER managedObjectContext];
    
    if (_remotePath == nil)
        return;
    
    NSDictionary *dict = [self deserializationContent];
    
    self.story = [DATA_MANAGER addStory:^(Story *story) {
    } inContext:self.childContext];
    
    self.story.id = self.storyShareID;
    [self setContent:self.story dictionary:dict];
    self.story.shared = @(YES);
    
    NSError* error;
    
    BOOL ok = [self.childContext save:&error];
    if (!ok) {
        NSLog(@"couldn't save child context: %@", error);
        return;
    }
    
    [DATA_MANAGER saveContext];
}

- (NSDictionary *)deserializationContent
{
    NSError *error = nil;
    NSString *contentLocalPath = [self loadFile:_remotePath];
    NSData *data = [NSData dataWithContentsOfFile:contentLocalPath];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    NSLog(@"ERROR %@ == %@", error, error.userInfo);
    
    return dict;
}

- (void)setContent:(id)class dictionary:(NSDictionary *)dict
{
    if (dict == nil) 
        return;
    
    for (NSString *key in dict.allKeys) {
        id object = dict[key];
        
        if ([key isEqualToString:DATE]) {
            // set the date to NOW so that the story will be shown first.
            self.story.date = [NSDate date];
        }
        else if ([key isEqualToString:USER]) {
            User *user = [DATA_MANAGER addUser:^(User *user) {
            } inContext:self.childContext];
            [self setContent:user dictionary:object];
            self.story.user = user;
        }
        else if ([key isEqualToString:MEDIA]) {
            NSArray *medias = object;
            NSMutableOrderedSet *storyMedias = [NSMutableOrderedSet new];
            for (NSDictionary *dictionary in medias) {
                Media *media = [DATA_MANAGER addMedia:^(Media *media) {
                } inContext:self.childContext];
                [self setContent:media dictionary:dictionary];
                [storyMedias addObject:media];
            }
            [self.story setMedia:storyMedias];
        }
        else if ([key isEqualToString:FRAME_RECT]) {
            NSArray *floats = [object componentsSeparatedByString:@","];
            CGRect rect = CGRectMake([floats[0] floatValue], [floats[1] floatValue], [floats[2] floatValue], [floats[3] floatValue]);
            NSValue *value = [NSValue valueWithCGRect:rect];
            [class setValue:value forKey:key];
        }
        else {
            if (object != [NSNull null]) {
                [class setValue:object forKey:key];
            }
        }
    }
}

#pragma mark - |AmazonServiceRequestDelegate| methods

- (void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse called: %@", response);
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData called");
}

- (void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    NSLog(@"didSendData called: %lld - %lld / %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
}

- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSLog(@"didCompleteWithResponse called: %@", response);
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError called: %@", error);
}

#pragma mark - Privates

- (NSString *)loadFile:(NSString *)remotePath
{
    NSString *key = [remotePath substringFromIndex:[SETTINGS.cdnBaseUrl length]];
    NSString *path = [[self getPathToDocuments] stringByAppendingString:@"/"];
    path = [path stringByAppendingString:key];
    
    NSError* error;
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    
    [self.transferManager synchronouslyDownloadFile:path bucket:SETTINGS.bucketName key:key];
    
    return path;
}

- (NSString*)getPathToDocuments
{
	NSArray	*arrPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [arrPaths objectAtIndex: 0];
}

@end
