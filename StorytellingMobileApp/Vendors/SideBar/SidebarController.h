//
//  SidebarController.h
//  MCV
//
//  Created by vaskov on 6/22/12.
//  Copyright (c) 2012 nix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuViewControllerDelegate.h"

extern NSString *SidebarControllerSelectedMenuNotification;

@class SidebarController;

typedef void(^SidebarWithSelectedMenu)(SidebarController *, NSIndexPath *);
typedef void(^SidebarBlock)(SidebarController *);



@interface SidebarController : UIViewController <MenuViewControllerDelegate>

@property(nonatomic, copy) SidebarWithSelectedMenu willSelectMenu;
@property(nonatomic, copy) SidebarBlock didOpenMenu;
@property(nonatomic, copy) SidebarBlock didCloseMenu;

@property(nonatomic, readonly) UIView* leftMarginGestureView;

@property (nonatomic, assign) BOOL menuDisabled;

- (void)setMenuDisabled:(BOOL)isModal animated:(BOOL)animated;

- (id)initWithMainControllers:(NSArray *)controllers menuController:(UIViewController *)menuController;
- (void)refreshButtonColor:(BOOL)isWhiteHighlighted;

@end



@interface UIViewController (SidebarController)
- (SidebarController*)sidebarController;
- (void)sideBar:(SidebarController *)sideBar didPresentControllerWithIndexPath:(NSIndexPath *)indexPath;
- (void)sideBar:(SidebarController *)sideBar menuDidChangeState:(BOOL)open;
@end
