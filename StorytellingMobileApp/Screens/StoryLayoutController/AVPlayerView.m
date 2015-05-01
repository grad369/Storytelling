//
//  AVPlayerView.m
//  StorytellingMobileApp
//
//  Created by Leonid Usov on 30.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "AVPlayerView.h"

#import "NSObject+MTKObserving.h"
#import "keypath.h"

NSString* kAVPlayerViewControlBroadcast = @"kAVPlayerViewControlBroadcast";
NSString* kAVPlayerViewControlBoradcastTestBlockKey = @"kAVPlayerViewControlBoradcastTestBlockKey";
NSString* kAVPlayerViewControlBoradcastCommandsKey = @"kAVPlayerViewControlBoradcastCommandsKey";

NSString* kAVPlayerViewPlaying = @"kAVPlayerViewPlaying";
NSString* kAVPlayerViewAutorepeating = @"kAVPlayerViewAutorepeating";
NSString* kAVPlayerViewMuting = @"kAVPlayerViewMuting";

@interface AVPlayerView ()
@property (nonatomic, assign) BOOL firstPlay;
@property (nonatomic, assign) BOOL firstPause;
@property (nonatomic, assign) BOOL seeking;
@end

@implementation AVPlayerView

@synthesize mute=_mute;

+(Class)layerClass
{
    return [AVPlayerLayer class];
}

+(void)sendControlBroadcast:(NSDictionary*)control forPlayersPassingTest:(AVPlayerViewControlTargetTest)test
{
    NSDictionary* ui = @{
                         kAVPlayerViewControlBoradcastCommandsKey: control,
                         kAVPlayerViewControlBoradcastTestBlockKey: (id)test ?: [NSNull null]
                         };
    [[NSNotificationCenter defaultCenter] postNotificationName:kAVPlayerViewControlBroadcast
                                                        object:self
                                                      userInfo:ui];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup
{
    self.autorepeat = YES;
    self.autoplay = NO;
    self.mute = YES;
    self.initialTime = kCMTimeZero;
    
    // when a player is detected on this cell
    // set it up
    [self observeObject:self
               property:@keypath(self.player)
              withBlock:^(__typeof(self) self, id object, id old, id newVal) {
                  if (newVal) {
                      __weak AVPlayer *player = (AVPlayer*)newVal;
                      
                      // by defalut - no sound
                      player.muted = self.mute;
                      
                      // don't stop playback when reached the end of the file
                      player.actionAtItemEnd = self.autorepeat ? AVPlayerActionAtItemEndNone : AVPlayerActionAtItemEndPause;
                      
                      [self observeNotification:AVPlayerItemDidPlayToEndTimeNotification
                                     fromObject:player.currentItem
                                      withBlock:^(__weak __typeof(self) self, NSNotification *notification) {
                                          if (notification) {
                                              if (self.finishPlaying!= nil)
                                                  self.finishPlaying(self);
                                              [self rewindAndAutoplay:self.autorepeat];
                                          }
                                      }];
                  }
              }];
    
    // watch for the plaback status for the case when playing via URL
    [self observeObject:self
             properties:@[
                          @keypath(self.player.currentItem.playbackLikelyToKeepUp),
                           @keypath(self.player.currentItem.playbackBufferFull)
                           ]
              withBlock:^(__typeof(self) self, id object, NSString *keyPath, id old, id newVal) {
                  // whenever either of the properties is YES
                  // continue playback
                  if (newVal && [newVal boolValue] && self.autoplay) {
                      [self play];
                  }
              }];
    
    // automatically start playing when the resource is ready
    [self observeObject:self
               property:@keypath(self.player.status)
              withBlock:^(__typeof(self) self, id object, id old, id newVal) {
                  if (self && newVal && [newVal integerValue] == AVPlayerStatusReadyToPlay) {
                      // IMPORTANT
                      // start play asynchrounously
                      // otherwise the system generates two same KVO notifications
                      // for rate property
                      dispatch_async(dispatch_get_main_queue(), ^{
                          if (CMTimeCompare(self.initialTime, kCMTimeZero) != 0) {
                              [self seekToTime:self.initialTime];
                          } else {
                              if (self.autoplay) {
                                  [self play];
                              }
                          }
                      });
                  }
              }];
    
    // allow for group control of all views
    [self observeNotification:kAVPlayerViewControlBroadcast
                   fromObject:nil
                    withBlock:^(__typeof(self) self, NSNotification *notification) {
                        if (nil == notification || nil == self) {
                            return;
                        }
                        AVPlayerViewControlTargetTest test = notification.userInfo[kAVPlayerViewControlBoradcastTestBlockKey];
                        
                        if (nil == test || [test isKindOfClass:[NSNull class]] || test(self)) {
                            
                            NSDictionary* commands = notification.userInfo[kAVPlayerViewControlBoradcastCommandsKey];
                            
                            // WARNING
                            // the code below will throw exceptions
                            // if commands dictionary will contain undefined properties
                            if (commands && NO == [commands isKindOfClass:[NSNull class]]) {
                                [self setValuesForKeysWithDictionary:commands];
                            }
                        }
                    }];
    
    self.firstPlay = self.firstPause = YES;
    [self observeNotification:AVPlayerViewStopPlayingVideoNotification withBlock:^(AVPlayerView  *self, NSNotification *notification) {
        if (!self.firstPause)
            [self pause];
        self.firstPause = NO;
    }];
    
    [self observeNotification:AVPlayerViewStartPlayingVideoNotification withBlock:^(AVPlayerView  *self, NSNotification *notification) {        
        if (!self.firstPlay) {
            self.mute = YES;
            [self play];
        }
        self.firstPlay = NO;
    }];
}

-(void)dealloc
{
    [self.player cancelPendingPrerolls];
    [self removeAllObservations];
    [self stop];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"AVPlayerView <%p>: %@", self, [(AVURLAsset*)self.player.currentItem.asset URL].lastPathComponent];
}

- (BOOL)isEqual:(AVPlayerView *)object
{
    if (![object isKindOfClass:[AVPlayerView class]]) {
        [super isEqual:object];
    }
    if (self.player == nil) {
        return NO;
    }
    NSURL *url1 = [(AVURLAsset*)self.player.currentItem.asset URL];
    NSURL *url2 = [(AVURLAsset*)object.player.currentItem.asset URL];
    return [url1 isEqual:url2];
}

#pragma mark - Properties

- (CMTime)currentTime
{
    return self.player.currentTime;
}

- (void)setCurrentTime:(CMTime)time
{
    [self seekToTime:time];
}

-(void)setAutorepeat:(BOOL)autorepeat
{
    _autorepeat = autorepeat;
    self.player.actionAtItemEnd = autorepeat ? AVPlayerActionAtItemEndNone : AVPlayerActionAtItemEndPause;
}

-(void)setAutoplay:(BOOL)autoplay
{    
    _autoplay = autoplay;
    
    if (!self.seeking && autoplay && self.player.status == AVPlayerStatusReadyToPlay) {
        [self.player prerollAtRate:1.0f completionHandler:^(BOOL finished) {
            if (finished && self.autoplay) {
                [self play];
            }
        }];
    }
    else {
        [self pause];
    }
}

- (void)setMute:(BOOL)mute
{
    _mute = mute;
    self.player.muted = mute;
}

- (BOOL)mute
{
    return self.player.muted || _mute;
}

- (void)play
{
    [self.player play];
    [self.seekView removeFromSuperview];
}

- (void)stop
{
    [self.player pause];
    self.player = nil;
}

- (void)setSeekView:(UIView *)seekView
{
    if (_seekView != seekView) {
        [_seekView removeFromSuperview];
        _seekView = seekView;
    }
}

- (void)seekToTime:(CMTime)time
{
    if (self.player.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    if (!CMTIME_IS_VALID(time)) {
        time = kCMTimeZero;
    }
    [self pause];
    self.seeking = YES;
    
    if (self.seekView != nil) {
        self.seekView.frame = self.bounds;
        [self addSubview:self.seekView];
    }
    
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [self.player prerollAtRate:1.0f completionHandler:^(BOOL finished) {
            self.seeking = NO;
            if (self.autoplay) {
                [self play];
            }
        }];
    }];
}

- (void)pause
{
    [self.player pause];
}

-(AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer*)self.layer;
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

#pragma mark - Actions

-(void)rewindAndAutoplay:(BOOL)autoplay
{
    self.autoplay = autoplay;
    [self.player seekToTime:kCMTimeZero];
}

-(void)setContentURL:(NSURL*)itemUrl
{
    [self.player cancelPendingPrerolls];
    
    if (itemUrl) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:itemUrl];
            AVPlayer* player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.player = player;
            });
        });
    }
    else {
        self.player = nil;
    }
}

@end
