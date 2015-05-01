//

#import "AmazonS3Upload.h"
#import "AmazonS3Defines.h"
#import "Settings.h"
#import "NSObject+MTKObserving.h"
#import "keypath.h"


@interface AmazonS3Upload () <AmazonServiceRequestDelegate>
@property (nonatomic, strong) AmazonS3Client* client;
@property (nonatomic, strong) S3TransferManager *transferManager;
@property (nonatomic, strong) NSMutableArray *uploads; // content UploadProcess
@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) NSManagedObjectID *storyID;
@property (nonatomic, strong) NSManagedObjectContext* childContext;
@property (nonatomic, strong) NSString* uploadedUserPhoto;

@property (nonatomic) float totalBytes;
@property (nonatomic) float uploadedBytes;

@property (nonatomic, strong) NSString* bucketName;

@end

@implementation AmazonS3Upload

- (id)initWithStory:(Story *)story
{
    self = [super init];
    if (self) {
        self.storyID = story.objectID;
        self.childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        self.childContext.parentContext = story.managedObjectContext;
        self.client = [[AmazonS3Client alloc]
                           initWithAccessKey:ACCESS_KEY
                           withSecretKey:SECRET_KEY];
        _client.endpoint = SETTINGS.cdnBaseUrl;
        self.bucketName = SETTINGS.bucketName;
        
        self.uploads = [NSMutableArray new];

        self.transferManager = [S3TransferManager new];
        self.transferManager.s3 = _client;
        self.transferManager.delegate = self;
        
        //disable multipart upload
        [self.transferManager setMultipartUploadThreshold:UINT32_MAX];
        
        [self observeProperty:@keypath(self.isCancelled) withBlock:^(__weak id self, id old, id newVal) {
            AmazonS3Upload* me = self;
            if ([newVal isKindOfClass:[NSNumber class]] && YES == [newVal boolValue]){
                [me.transferManager cancelAllTransfers];
            }
        }];

        self.uploadedUserPhoto = nil;
    }
    return self;
}

#pragma mark - |NSOperation| methods

- (void)main
{    
    self.story = (Story*)[self.childContext objectWithID:self.storyID];
    
    if (_story == nil)
        return;
    
    NSLog(@"s3 upload main");
    
    NSString* (^uploadBlock)(NSString *path, NSString* content) = ^ NSString* (NSString *path, NSString* content) {
        if (NO == [[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return path;
        }
        
        if (self.isCancelled) {
            return @"";
        }
        NSString *commonPath = [NSString stringWithFormat:@"%@/", [self getPathToDocuments]];
        NSString *key = [path substringFromIndex:[commonPath length]];
        return [self uploadFile:path key:key type:content];
    };
    
    if (self.isCancelled) {
        return;
    }
    
    // Calculate total size
    NSURL* photoURL = [NSURL URLWithString:_story.user.photo];
    if (photoURL.isFileURL || [[NSFileManager defaultManager] fileExistsAtPath:photoURL.path]) {
        self.totalBytes += [self sizeOfFile:photoURL.path];
    }
    
    for (Media *media in _story.media) {
        self.totalBytes += [self sizeOfFile:media.largeImageURL];
        self.totalBytes += [self sizeOfFile:media.largeVideoURL];
        self.totalBytes += [self sizeOfFile:media.smallImageURL];
        self.totalBytes += [self sizeOfFile:media.smallVideoURL];
    }
    
    // Upload
    if (photoURL.isFileURL || [[NSFileManager defaultManager] fileExistsAtPath:photoURL.path]) {
        self.uploadedUserPhoto =
        [self uploadFile:photoURL.path
                     key:[NSString stringWithFormat:@"%@/user/%@", _story.id, photoURL.lastPathComponent]
                    type:@"image/jpeg"
         ];
    }
    
    for (Media *media in _story.media) {
        if (self.isCancelled) {
            break;
        }
        media.largeImageURL = uploadBlock(media.largeImageURL, @"image/jpeg");
        media.largeVideoURL = uploadBlock(media.largeVideoURL, @"video/mp4");
        media.smallImageURL = uploadBlock(media.smallImageURL, @"image/jpeg");
        media.smallVideoURL = uploadBlock(media.smallVideoURL, @"video/mp4");
    }
    
    NSString *jsonPath = [self writeJson];
    if (jsonPath != nil) {
        self.totalBytes += [self sizeOfFile:jsonPath];
        uploadBlock(jsonPath, @"application/json");
    }
    
    [self.transferManager.operationQueue waitUntilAllOperationsAreFinished];
    
    if (NO == self.isCancelled) {
        NSError* error;
        
        // save only the "shared" flag
        // and stay with all local links
        @try {
            self.story = nil;
            [self.childContext reset];
        }
        @catch (NSException *exception) {
            NSLog(@"ERROR upload main:  %@", exception);
        }       
        
        self.story = (Story*)[self.childContext objectWithID:self.storyID];
        self.story.shared = @(YES);
        
        BOOL ok = [self.childContext save:&error];
        if (!ok) {
            NSLog(@"couldn't save child context: %@", error);
            return;
        }
    }
}

- (float)sizeOfFile:(NSString *)path
{
    if (path.length == 0) {
        return 0;
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:&error];
    
    if (error != nil) {
        NSLog(@"Error reading attributes %@", error);
        return 0;
    }
    
    float fileSize = [[fileAttributes objectForKey:NSFileSize] floatValue];
    return fileSize;
}

-(NSURL *)shareURL
{
    if (self.story && self.isFinished && self.story.shared.boolValue) {
        return self.story.shareURL;
    }
    return nil;
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
    self.uploadedBytes += bytesWritten;
    
    if (self.progressBlock) {
        self.progressBlock(self.uploadedBytes / self.totalBytes);
    }
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

- (NSString*)getPathToDocuments
{
	NSArray	*arrPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [arrPaths objectAtIndex: 0];
}

- (void)createBucketName:(NSString *)name
{
    S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:name
                                                                                   andRegion:[S3Region USWest2]];
    @try {
        S3CreateBucketResponse *createBucketResponse = [_client createBucket:createBucketRequest];
        if(createBucketResponse.error != nil)
        {
            NSLog(@"Error: %@", createBucketResponse.error);
        }
    }@catch(AmazonServiceException *exception){
        if(![@"BucketAlreadyOwnedByYou" isEqualToString: exception.errorCode]) {
            NSLog(@"Unable to create bucket: %@", exception.error);
        }
    }
}

- (BOOL)isHaveBucket
{
    NSArray *buckets = [self.client listBuckets];
    for (S3Bucket *bucket in buckets) {
        if ([bucket.name isEqualToString:self.bucketName]) {
            return YES;
        }
    }
    return NO;
}

-(NSString*)makeRemotePathWithKey:(NSString*)key
{
    NSString* remotePath;
    
    NSString* endpoint = self.client.endpoint;
    if ([endpoint isEqualToString:[AmazonEndpoints s3Endpoint:EU_WEST_1]]) {
        // our CDN points of the EU_WEST_1 bucket
        remotePath = [CDN_PATH stringByAppendingPathComponent:key];
    }
    else {
        remotePath = [[endpoint stringByAppendingPathComponent:self.bucketName] stringByAppendingPathComponent:key];
    }
    return remotePath;
}

- (NSString *)uploadFile:(NSString *)pathLocal key:(NSString *)key type:(NSString*)contentType
{
    NSString *remotePath = nil;
    @try {
        S3PutObjectRequest *request = [[S3PutObjectRequest alloc] initWithKey:key inBucket:self.bucketName];
        request.filename = pathLocal;
        request.delegate = self;
        request.cannedACL = [S3CannedACL publicReadWrite];
        request.contentType = contentType;
        
        [self.transferManager upload:request];
        
        remotePath = [self makeRemotePathWithKey:key];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", [exception description]);
    }
    
    return self.isCancelled ? @"" : remotePath;
}

- (NSString *)writeJson // return fullPath
{
    NSError *writeError = nil;
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@/content.json", [self getPathToDocuments], _story.id];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
        return nil;
    
    @try
    {
        NSDictionary *dict = [self getContent:_story];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&writeError];
        
        [jsonData writeToFile:fullPath atomically:NO];
        NSLog(@"%@", writeError);
        
        return fullPath;
    }
    @catch(NSException *ex){
        NSLog(@"%@ %@", ex.userInfo, ex);
        return nil;
    }
}

- (NSDictionary *)getContent:(id)class
{
    __block NSMutableDictionary *commonDictionary = [NSMutableDictionary new];
    NSArray *properties = [class properties][NSStringFromClass([class class])];
    
    for (NSString *key in properties) {
        id object = [class valueForKey:key];
        if (object == nil)
            continue;
        
        if ([key isEqualToString:DATE]) {
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateFormat:DATE_FORMAT];
            NSString *dateStr = [formatter stringFromDate:object];
            commonDictionary[key] = dateStr;
        }
        else if ([key isEqualToString:USER]) {
            User* user = (User*)object;
            commonDictionary[key] = @{
                                      @"name": user.name,
                                      @"photo": self.uploadedUserPhoto ? self.uploadedUserPhoto : [NSNull null]
                                      };
        }
        else if ([key isEqualToString:MEDIA]) {
            NSMutableArray *mediaArray = [NSMutableArray new];
            NSOrderedSet *set = object;
            for (Media *media in set) {
                [mediaArray addObject:[self getContent:media]];
            }
            commonDictionary[MEDIA] = mediaArray;
        }
        else if ([key isEqualToString:FRAME_RECT]) {
            NSValue *value = object;
            CGRect rect = [value CGRectValue];
            NSString *rectStr = [NSString stringWithFormat:@"%f,%f,%f,%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
            commonDictionary[key] = rectStr;
        }
        else if ([key isEqualToString:STORY]){
            continue;
        }
        else if ([key isEqualToString:STORIES]){
            continue;
        }
        else {
            commonDictionary[key] = object;
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:commonDictionary];
}

@end

