//
//  ConvertStoryLocal.m
//  StorytellingMobileApp
//
//  Created by vaskov on 09.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "ConvertStoryLocal.h"
#import "VideoConverter.h"
#import "Settings.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage-Extensions.h"
#import "DataManager.h"
#import "ALAssetsLibrary+Category.h"
#import "NSObject+MTKObserving.h"
#import "keypath.h"

@interface ConvertStoryLocal ()
@property (nonatomic, strong) VideoConverter *videoConverter;
@property (nonatomic, assign) long long totalBytes;
@property (nonatomic, assign) long long convertBytes;
@property (nonatomic, strong) Story *story;
@property (nonatomic, strong) NSManagedObjectID *storyID;
@property (nonatomic, strong) NSManagedObjectContext* childContext;
@property (nonatomic, strong) NSMutableDictionary* assetsToProcess;
@property (nonatomic, strong) NSMutableDictionary* bytesProcessed;
@property (nonatomic, strong) NSMutableDictionary* convertingVideos;

@end

@implementation ConvertStoryLocal

- (instancetype)initWithStory:(Story *)story
{
    self = [super init];
    if (self) {
        self.videoConverter = [VideoConverter new];
        self.convertingVideos = [NSMutableDictionary new];
        _convertBytes = 0;
        _totalBytes = 0;
        
        self.storyID = story.objectID;
        self.childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        self.childContext.parentContext = story.managedObjectContext;

        
        [self observeProperty:@keypath(self.isCancelled) withBlock:^(__weak id self, id old, id newVal) {
            ConvertStoryLocal* me = self;
            [me.videoConverter cancelAllSessions];
        }];
        
    }
    return self;
}

-(void)dealloc
{
    [self removeAllObservations];
}

- (void)main
{
    NSLog(@"convertstory main");
    
    
    self.story = (Story*)[self.childContext objectWithID:self.storyID];
    
    if (self.story) {
        
        NSCondition* assetReady = [NSCondition new];
        
        self.assetsToProcess = [NSMutableDictionary dictionary];
        self.bytesProcessed = [NSMutableDictionary dictionary];
        __block NSUInteger pendingAssetCount = 0;
        self.totalBytes = 0;
        self.convertBytes = 0;
        
        void(^getAsset)(NSString* path) = ^(NSString* path){
            if (path) {
                [assetReady lock];
                
                ALAsset* asset = self.assetsToProcess[path];
                if (nil == asset) {
                    self.assetsToProcess[path] = @(1);
                    pendingAssetCount ++;
                    
                    [[ALAssetsLibrary sharedLibrary]  assetForURL:[NSURL URLWithString:path]
                                                      resultBlock:^(ALAsset *asset) {
                        [assetReady lock];
                        if (asset) {
                            // has to be number
                            NSNumber* mul = self.assetsToProcess[path];
                            
                            [self.assetsToProcess setObject:asset forKey:path];
                            self.totalBytes += asset.defaultRepresentation.size * [mul unsignedLongLongValue];
                        }
                        else {
                            [self.assetsToProcess removeObjectForKey:path];
                        }
                        
                        pendingAssetCount--;
                        [assetReady signal];
                        [assetReady unlock];
                                                          
                    } failureBlock:^(NSError* error){
                        [assetReady lock];
                        [self.assetsToProcess removeObjectForKey:path];
                        
                        pendingAssetCount--;
                        [assetReady signal];
                        [assetReady unlock];
                    }];
                }
                else if ([asset isKindOfClass:[NSNumber class]]) {
                    self.assetsToProcess[path] = @([(NSNumber*)asset integerValue] + 1);
                }
                else {
                    self.totalBytes += asset.defaultRepresentation.size;
                }
                
                [assetReady unlock];
            }
        };
        
        for (Media *media in _story.media) {
            getAsset(media.smallImageURL);
            getAsset(media.largeImageURL);
            getAsset(media.smallVideoURL);
            getAsset(media.largeVideoURL);
        }
        
        [assetReady lock];
        while (pendingAssetCount) {
            [assetReady wait];
        }
        [assetReady unlock];
        
        [self refreshProcess];
        [self convert];
    }
    
    NSError* error;
    
    if (NO == self.isCancelled) {
        BOOL ok = [self.childContext save:&error];
        if (!ok) {
            NSLog(@"couldn't save child context: %@", error);
            return;
        }
    }
    
}

- (void)convert
{
    
    [self convertToFolder:@"/small/media" isLarge:NO];
    [self convertToFolder:@"/large/media" isLarge:YES];
    
}

- (void)convertToFolder:(NSString *)folder isLarge:(BOOL)isLarge
{
    NSMutableString *mainPath = [NSMutableString stringWithFormat:@"/%@", _story.id];
    NSString *path = [self createFolder:folder mainPath:mainPath];
    
    for (Media *media in _story.media) {
        NSString *imagePath = isLarge ? media.largeImageURL : media.smallImageURL;
        
        if (self.isCancelled) {
            break;
        }
        
        if ([imagePath hasPrefix:@"assets-library"]) {
            [self createImageNameWithFolder:path fullPathSource:imagePath result:^(NSString *outputName) {
                ImageSizeType type = isLarge ? SETTINGS.bigImageSizeType : SETTINGS.smallImageSizeType;
                [self convertImage:imagePath outputName:outputName toType:type];
                isLarge ? (media.largeImageURL = outputName) : (media.smallImageURL = outputName);
                [self assetPath:imagePath tag:isLarge?@"L":@"S" progress:1];
            }];
        }
        
        NSString *videoPath = isLarge ? media.largeVideoURL : media.smallVideoURL;
        
        if (self.isCancelled) {
            break;
        }
        
        if ([videoPath hasPrefix:@"assets-library"]) {
            [self createVideoNameWithFolder:path fullPathSource:videoPath result:^(ALAsset *videoAsset, NSString* outputName) {
                __weak ConvertStoryLocal *selfId = self;
                CompressOfVideoType videoType = isLarge ? SETTINGS.bigCompressVideoType : SETTINGS.smallCompressVideoType;
            
                NSString *exportKey = [_videoConverter convertVideo:videoAsset
                                                           outputName:outputName
                                                               toType:videoType
                                                             progress:^(NSString *key, CGFloat progress) {
                                                                 if (key != nil) {
                                                                     [selfId videoKey:key progress:progress];
                                                                 }
                                                             }];
                
                if (exportKey != nil) {
                    
                    AVAssetExportSessionStatus status;
                    self.convertingVideos[exportKey] = videoAsset;
                    [_videoConverter waitUntilSessionWithKey:exportKey isFinished:&status];
                    [self videoKey:exportKey progress:1];
                    if (isLarge) {
                        media.largeVideoURL = outputName;
                    }
                    else {
                        media.smallVideoURL = outputName;
                    }
                }
            }];
        }
    }
}

-(void)videoKey:(NSString*)key progress:(CGFloat)progress
{
    @synchronized(self.bytesProcessed)
    {
        ALAsset* asset = self.convertingVideos[key];
        if (asset) {
            NSString* tag = [asset.defaultRepresentation.url.absoluteString stringByAppendingString:key];
            self.bytesProcessed[tag] = [NSNumber numberWithLongLong:(asset.defaultRepresentation.size * progress)];
        }
    }
    [self refreshProcess];
}

-(void)assetPath:(NSString*)path tag:(NSString*)tag progress:(CGFloat)progress
{
    @synchronized(self.bytesProcessed)
    {
        ALAsset* asset = self.assetsToProcess[path];
        if (asset) {
            tag = [path stringByAppendingString:tag ? tag : @""];
            self.bytesProcessed[tag] = [NSNumber numberWithLongLong:(asset.defaultRepresentation.size * progress)];
        }
    }
    [self refreshProcess];
}

- (void)createImageNameWithFolder:(NSString *)pathFolder
                   fullPathSource:(NSString *)imagePath
                           result:(void(^)(NSString* outPath))resultBlock
{
    if (imagePath == nil)
        return;
    NSURL* imageURL = [NSURL URLWithString:imagePath];
    if ([imageURL isFileURL]) {
        NSString *fileName = imageURL.lastPathComponent;
        NSString *outPath = [NSString  stringWithFormat:@"%@%@/%@.png", [self getPathToDocuments], pathFolder, [fileName stringByDeletingPathExtension]];
        resultBlock(outPath);
    }
    else {
        ALAsset *asset = self.assetsToProcess[imagePath];
        NSString *fileName = asset.defaultRepresentation.filename;
        NSString *outPath = [NSString  stringWithFormat:@"%@%@/%@.png", [self getPathToDocuments], pathFolder, [fileName stringByDeletingPathExtension]];
        resultBlock(outPath);
    }
}

- (void)createVideoNameWithFolder:(NSString *)pathFolder
                   fullPathSource:(NSString *)videoPath
                           result:(void(^)(ALAsset *videoAsset, NSString *outPath))resultBlock
{
    if (videoPath == nil)
        return;
    
    [ALAssetsLibrary assetWithPath:videoPath result:^(ALAsset *asset) {
        NSString *fileName = asset.defaultRepresentation.filename;
        NSString *outPath = [NSString  stringWithFormat:@"%@%@/%@.mp4", [self getPathToDocuments], pathFolder, [fileName stringByDeletingPathExtension]];
        resultBlock(asset, outPath);
    } failureBlock:^(NSError *error) {
    } wait:YES];
}

- (NSString *)createFolder:(NSString *)folder mainPath:(NSString *)mainPath
{
    NSMutableString *path = [NSMutableString stringWithString:mainPath];
    [path appendString:folder];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        [self createFolder:path];
    return path;
}

- (NSString *)getPathToDocuments
{
	NSArray	*arrPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
	return [arrPaths objectAtIndex: 0];
}

- (void)createFolder:(NSString *)path
{
    NSMutableString *currentFolder = [NSMutableString stringWithFormat:@"%@", [self getPathToDocuments]];
    [currentFolder appendString:path];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:currentFolder withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)convertImage:(NSString *)path outputName:(NSString *)fileName toType:(ImageSizeType)type
{
    if (path == nil)
        return;
    
    NSLog(@"convertImage fileName %@ start", fileName);
    
    NSCondition *condition = [NSCondition new];
    __block BOOL ready = NO;
    
    void(^setReady)() = ^{
        [condition lock];
        ready = YES;
        [condition signal];
        [condition unlock];
    };
    
    void(^savedBlock)() = ^(UIImage *image){
        if (NO == self.isCancelled) {
            CGSize imageSize = [image sizeByScalingProportionallyToSize:[self sizeWithType:type imageRatio:image.size.width / image.size.height]];
            
            NSData *data = UIImageJPEGRepresentation([image imageByScalingProportionallyToSize:imageSize], 1);
            [data writeToFile:fileName atomically:YES];
            setReady();
        }
    };
    NSURL* fileURL = [NSURL URLWithString:path];
    if (fileURL.isFileURL) {
        UIImage* image = [UIImage imageWithContentsOfFile:fileURL.path];
        savedBlock(image);
    }
    else {
        ALAsset* asset = self.assetsToProcess[path];
        UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage scale:1 orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        savedBlock(image);
    }
    
    [condition lock];
    while (NO == ready && NO == self.isCancelled) {
        [condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    [condition unlock];
    NSLog(@"convertImage fileName %@ end", fileName);
}

- (CGSize)sizeWithType:(ImageSizeType)type imageRatio:(CGFloat)ratio
{
    CGFloat width, height;
    switch (type) {
        case ImageSizeType03MP:
            width = 480.0f, height = 640.0f;
        break;
        
        case ImageSizeType07MP:
            width = 768.0f, height = 1024.0f;
        break;
        
        case ImageSizeType1MP:
            width = 800.0f, height = 1280.0f;
        break;
        
        case ImageSizeType2MP:
            width = 1080.0f, height = 1920.0f;
        break;
            
        default:
            break;
    }
    
    if (ratio > 1) {
        CGFloat tmp = width;
        width = height;
        height = tmp;
    }
    
    return CGSizeMake(width, height);
}

- (void)refreshProcess
{
    __block float bytesCompleted = 0;
    @synchronized(self.bytesProcessed)
    {
        [self.bytesProcessed enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSNumber class]]) {
                bytesCompleted += [obj floatValue];
            }
        }];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressBlock) {
            self.progressBlock(self.totalBytes ? bytesCompleted / (float)self.totalBytes : 1);
        }
    });
}

@end
