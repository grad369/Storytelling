//
//  AVPlayerView.h
//  StorytellingMobileApp
//
//  Created by Leonid Usov on 30.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// used to controll all instances of AVPlayerView
extern NSString* kAVPlayerViewControlBroadcast;
extern NSString* kAVPlayerViewControlBoradcastTestBlockKey;
extern NSString* kAVPlayerViewControlBoradcastCommandsKey;

@class AVPlayerView;

typedef BOOL (^AVPlayerViewControlTargetTest)(AVPlayerView* playerView);

@interface AVPlayerView : UIView

@property (nonatomic, strong) AVPlayer* player;
@property (nonatomic, readonly) AVPlayerLayer* playerLayer;

@property (nonatomic, assign) BOOL autorepeat;
@property (nonatomic, assign) BOOL autoplay;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) CMTime initialTime;
@property (nonatomic, assign) CMTime currentTime;
@property (nonatomic, weak  ) UIView *seekView;

-(void)setContentURL:(NSURL*)itemUrl;
-(void)rewindAndAutoplay:(BOOL)autoplay;

+(void)sendControlBroadcast:(NSDictionary*)control forPlayersPassingTest:(AVPlayerViewControlTargetTest)test;

@property (nonatomic, copy) void(^finishPlaying)(AVPlayerView *);

@end
