//
//  VideoConverter.m
//  StorytellingMobileApp
//
//  Created by vaskov on 25.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "VideoConverter.h"
#import "ALAssetsLibrary+Category.h"

@interface VideoConverter ()
@property (nonatomic, strong) NSMutableDictionary *exportSessions;
@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) void(^timerBlock)();
@end

@implementation VideoConverter

- (id)init
{
    self = [super init];
    if (self) {
        self.exportSessions = [NSMutableDictionary new];
        self.condition = [NSCondition new];
    }
    return self;
}

#pragma mark - Publics

-(void)waitUntilSessionWithKey:(NSString *)key isFinished:(AVAssetExportSessionStatus *)status
{
    AVAssetExportSessionStatus sessionStatus = AVAssetExportSessionStatusUnknown;
    [self.condition lock];
    
    AVAssetExportSession *session = self.exportSessions[key];
    
    while (session) {
        if ([session isKindOfClass:[AVAssetExportSession class]]) {
            sessionStatus = [session status];
        }
        else if ([session isKindOfClass:[NSNumber class]]) {
            sessionStatus = [(NSNumber*)session integerValue];
        }
        
        switch (sessionStatus) {
            case AVAssetExportSessionStatusWaiting:
            case AVAssetExportSessionStatusExporting:
            {
                NSDate *date = [NSDate dateWithTimeIntervalSinceNow:2];
                [self.condition waitUntilDate:date];
                if (_timerBlock)
                    _timerBlock();                
                break;
            }
            default:
                session = nil;
                break;
        }
    }
    
    if (status)
        *status = sessionStatus;
    
    [self.condition unlock];
}

- (NSString *)convertVideo:(ALAsset* )videoAsset
                outputName:(NSString *)fileName
                    toType:(CompressOfVideoType)type
                  progress:(ProgressBlock)progressBlock
{
    
    NSLog(@"videoConvert %@ start", fileName);
    
    
    AVURLAsset *avAsset = nil;
    
    avAsset = [[AVURLAsset alloc] initWithURL:videoAsset.defaultRepresentation.url options:nil];
    
    NSString *presetName = [self presetNameFromType:type];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:presetName]) {
        
        NSString *keyForExportSession = [[NSUUID UUID] UUIDString];
        NSURL *outputURL = [NSURL fileURLWithPath:fileName];
        
        __block AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:avAsset presetName:presetName];
        exportSession.outputURL = outputURL;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        self.timerBlock = ^{
            progressBlock(keyForExportSession, exportSession.progress);
        };
        
        [self.condition lock];
        
        [_exportSessions setObject:exportSession forKey:keyForExportSession];
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"Export Completed");
                    break;
                case AVAssetExportSessionStatusWaiting:
                    NSLog(@"Export Waiting");
                    break;
                case AVAssetExportSessionStatusExporting:
                    NSLog(@"Export Exporting");
                    break;
                case AVAssetExportSessionStatusFailed:
                {
                    NSError *error = [exportSession error];
                    NSLog(@"Export failed: %@", [error localizedDescription]);
                    
                    break;
                }
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    
                    break;
                default:
                    break;
            }
            
            [self removeSessionAndObservationWithKey:keyForExportSession];
            NSLog(@"videoConvert %@ end", fileName);
        }];
        
        if (_exportSessions[keyForExportSession] == nil) {
            keyForExportSession = nil;
        }
        
        [self.condition unlock];
        
        return keyForExportSession;
    }
    
    return nil;
}

- (void)cancelSessionWithKey:(NSString *)key
{
    
    NSArray* sessions;
    
    [self.condition lock];
    sessions = self.exportSessions.allValues;
    [self.condition unlock];
    
    for (AVAssetExportSession* s in sessions) {
        if ([s isKindOfClass:[AVAssetExportSession class]]) {
            [s cancelExport];
        }
    }
}

- (void)cancelAllSessions
{
    for (NSString *exportSessionKey in [_exportSessions allKeys]) {
        [self cancelSessionWithKey:exportSessionKey];
    }
}

#pragma mark - Privates

- (NSString *)presetNameFromType:(CompressOfVideoType)type
{
    NSString *name;
    switch (type) {
        case CompressOfVideoTypeLow:
            name = AVAssetExportPresetLowQuality;
        break;
        case CompressOfVideoTypeMedium:
            name = AVAssetExportPresetMediumQuality;
            break;
        case CompressOfVideoTypeHigh:
            name = AVAssetExportPresetHighestQuality;
            break;
        case CompressOfVideoType640x480:
            name = AVAssetExportPreset640x480;
            break;
        case CompressOfVideoType960x540:
            name = AVAssetExportPreset960x540;
            break;
        case CompressOfVideoType1280x720:
            name = AVAssetExportPreset1280x720;
            break;
            
        default:
            break;
    }
    
    return name;
}

- (void)removeSessionAndObservationWithKey:(NSString *)key
{
    [self removeWithKey:key exportBlock:^(AVAssetExportSession *session) {
    }];
}

- (void)removeWithKey:(NSString *)key exportBlock:(void(^)(AVAssetExportSession *session))block
{
    [self.condition lock];
    
    AVAssetExportSession *session = self.exportSessions[key];
    if (session != nil) {
        block(session);
        self.exportSessions[key] = @(session.status);
        [self.condition signal];
    }
    [self.condition unlock];
}

@end
