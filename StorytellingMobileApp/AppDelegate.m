//
//  AppDelegate.m
//  StorytellingMobileApp
//
//  Created by vaskov on 23.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "AppDelegate.h"
#import "MenuViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AmazonS3Download.h"
#import "HomeViewController.h"
#import "Settings.h"
#import "DataManager.h"
#import "AmazonS3Defines.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSURL *storeURL = [DATA_MANAGER storeURL];
    if (![[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        [Story firstInitStories];
    }
    
    [SETTINGS setCdnBaseUrl:[SETTINGS.class cdnBaseUrlOptions][EU_WEST_1]];
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self.window setRootViewController:[self addSideBar]];
    
    [self.window makeKeyAndVisible];    
    
    return YES;
}

- (SidebarController *)addSideBar
{
    NSArray *(^arrayControllersForSection)() = ^ NSArray*(NSArray *controllersStr){
        NSMutableArray *controllers = [NSMutableArray new];
        
        for (NSString *controllerStr in controllersStr)
        {
            UIViewController *controller = [NSClassFromString(controllerStr) new];
            
            UINavigationController *navigationC = [[UINavigationController alloc] initWithRootViewController:controller];
            [navigationC setNavigationBarHidden:YES];
            
            [controllers addObject:navigationC];
        }
        return [NSArray arrayWithArray:controllers];
    };
    
    NSMutableArray *controllers = [NSMutableArray new];
    [controllers addObject:arrayControllersForSection(@[@"HomeViewController"])];
    [controllers addObject:arrayControllersForSection(@[@"ProfileViewController", @"SettingsViewController"])];
    
    MenuViewController *menuVC = [[MenuViewController alloc] initWithNibName:@"MenuViewController" bundle:nil];
    self.sidebarC = [[SidebarController alloc] initWithMainControllers:controllers menuController:menuVC];
    
    self.sidebarC.didOpenMenu = ^(SidebarController *sideBarC) {
        [menuVC showCreateStoryButton]; };
    self.sidebarC.didCloseMenu = ^(SidebarController *sideBarC) {
        [menuVC hideCreateStoryButton]; };
    
    menuVC.delegate = self.sidebarC;
    [menuVC hideCreateStoryButton];
    
    return self.sidebarC;
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSOperationQueue *queue = [NSOperationQueue new];
    AmazonS3Download *download = [[AmazonS3Download alloc] initWithIdStory:url.host];
    
    [download setCompletionBlock:^{
        
        // give the main controller the time to setup
        double delayInSeconds = 0.85;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            NSNotification* n = [NSNotification notificationWithName:kHomeViewControllerOpenStoryNotification object:self userInfo:@{kHomeViewControllerOpenStoryNotificationStoryURL:url}];
            [[NSNotificationCenter defaultCenter] postNotification:n];
        });
    }];
    
    [queue addOperation:download];
    
    return YES;
}


@end
