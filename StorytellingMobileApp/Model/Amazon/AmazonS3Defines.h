//
//  AmazonS3Defines.h
//  StorytellingMobileApp
//
//  Created by vaskov on 14.04.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import <AWSRuntime/AWSRuntime.h>
#import "Model.h"
#import "DataManager.h"
#import "NSObject-Utilities.h"

#define ACCESS_KEY  @"AKIAJ2L3DHETVA6KPDOA"
#define SECRET_KEY  @"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"
#define BUCKET      @"dev.poc.storytelling.ie.myheritage.com"
#define S3_PATH     @"https://s3-eu-west-1.amazonaws.com/dev.poc.storytelling.ie.myheritage.com/"
#define CDN_PATH    @"http://dd0s2n1oswkcq.cloudfront.net/"

#define DATE       @"date"
#define MEDIA      @"media"
#define USER       @"user"
#define FRAME_RECT @"frameRect"
#define STORY      @"story"
#define STORIES    @"stories"

#define DATE_FORMAT @"yyyy-MM-dd HH:mm"