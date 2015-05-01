//
//  SidebarController.m
//  MCV
//
//  Created vaskov on 6/22/12.
//  Copyright (c) 2012 nix. All rights reserved.
//

#import "SidebarController.h"
#import "UIView+Helpers.h"

NSString *SidebarControllerSelectedMenuNotification = @"SidebarControllerSelectedMenuNotification";

@implementation SidebarController 
{
    BOOL _menuOpened;
    CGFloat _widthMenuVC;
    CGFloat _widthMainVC;
    CGFloat _heightMainNC;
    
    UISwipeGestureRecognizer *_swipeL, *_swipeR;
    
    UINavigationController *_mainNC;
    UIViewController *_menuVC;
    
    NSArray *_navigationsArray;
    NSIndexPath *_currentIndexPath;
    UIView *_gestureView;
    UIButton *_menuButton;
}

static const float GESTURE_VIEW_WIDTH = 15;

- (id)initWithMainControllers:(NSArray *)controllers menuController:(UIViewController *)menuController
{
    self = [super init];
    
    if (self)
    {
        CGSize sizeMainScreen = [[UIScreen mainScreen] bounds].size;
        
        _navigationsArray = controllers;
        
        _widthMenuVC = sizeMainScreen.width - 55.0f;
        _heightMainNC = sizeMainScreen.height;
        _widthMainVC = sizeMainScreen.width;
        _menuOpened = NO;
                
        _menuVC = menuController;
        _menuVC.view.frame = CGRectMake(-_widthMenuVC, 0, _widthMenuVC, _heightMainNC);
        self.view.backgroundColor = [UIColor blackColor];
        [self.view insertSubview:_menuVC.view atIndex:0];
        
        _currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        
        [self addChildViewController:menuController];
        
        for (NSArray *array in controllers) {
            for (UIViewController *controller in array) {
                [self addChildViewController:controller];
            }
        }
    }
    return self;
}

#pragma mark View life

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self openFirstController];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return  UIStatusBarStyleLightContent;
}

-(UIViewController *)childViewControllerForStatusBarHidden
{
    return _mainNC;
}

-(UIViewController *)childViewControllerForStatusBarStyle
{
    return _mainNC;
}

#pragma mark Action

-(void)setMenuDisabled:(BOOL)isModal
{
    [self setMenuDisabled:isModal animated:NO];
}

-(BOOL)menuDisabled
{
    return _menuButton.hidden;
}

- (void)setMenuDisabled:(BOOL)isModal animated:(BOOL)animated
{
    _gestureView.userInteractionEnabled = !isModal;
    _menuButton.hidden = isModal;
    if (animated) {
        CATransition* t = [CATransition animation];
        t.duration = 0.3;
        [_menuButton.layer addAnimation:t forKey:kCATransition];
    }
}

- (void)close
{
    if (_menuOpened)
    {
        [UIView animateWithDuration:0.4f animations:^{
            _mainNC.view.left = 0;
            _menuVC.view.left = -_widthMenuVC;
            _gestureView.width = GESTURE_VIEW_WIDTH;
        } completion:^(BOOL finished) {
            _menuOpened = !_menuOpened;
            if (_didCloseMenu != nil)
                _didCloseMenu(self);
            [_mainNC.topViewController sideBar:self menuDidChangeState:_menuOpened];
        }];        
    }
}

- (void)open
{
    if (!_menuOpened)
    {
        [_mainNC.view endEditing:YES];
        [UIView animateWithDuration:0.4f animations:^{
            _mainNC.view.left = _widthMenuVC;
            _menuVC.view.left = 0;
            _gestureView.width = [UIApplication sharedApplication].keyWindow.width - _widthMenuVC;
        } completion:^(BOOL finished) {
            _menuOpened = !_menuOpened;
            [_gestureView.superview bringSubviewToFront:_gestureView];
            [_menuButton.superview bringSubviewToFront:_menuButton];
            if (_didOpenMenu != nil)
                _didOpenMenu(self);
            [_mainNC.topViewController sideBar:self menuDidChangeState:_menuOpened];
        }];
    }
}

- (void)menuChange
{
    if (_menuOpened)
    {
        [self close];
    }
    else
    {
        [self open];
    }
}

#pragma mark MenuViewControllerDelegate

- (void)didSelectElementWithIndexPath:(NSIndexPath *)indexPath
{
    if (_willSelectMenu != nil)
        _willSelectMenu(self, indexPath);
    
    if ([_currentIndexPath isEqual:indexPath])
    {
        _currentIndexPath = indexPath;
        
        [self close];
    }
    else
    {
        _currentIndexPath = indexPath;
       
        NSArray *controllers = _navigationsArray[indexPath.section];
        UINavigationController *ncPush = (indexPath.section == 0) ? controllers[0] : controllers[indexPath.row];
        [self closeAndChange:ncPush];
        [ncPush.viewControllers.firstObject sideBar:self didPresentControllerWithIndexPath:indexPath];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SidebarControllerSelectedMenuNotification object:nil];
}

#pragma mark Privates

- (void)addRecognizers
{
    _swipeR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(open)];
    [_swipeR setDirection:UISwipeGestureRecognizerDirectionRight];
    [_gestureView addGestureRecognizer:_swipeR];
    
    _swipeL = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    [_swipeL setDirection:UISwipeGestureRecognizerDirectionLeft];
    [_gestureView addGestureRecognizer:_swipeL];
    
    UISwipeGestureRecognizer* sl = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    [sl setDirection:UISwipeGestureRecognizerDirectionLeft];
    [_menuVC.view addGestureRecognizer:sl];
}

-(UIView *)leftMarginGestureView
{
    return _gestureView;
}

- (void)openFirstController
{
    _mainNC = _navigationsArray[0][0];
    [self.view addSubview:_mainNC.view];
    [self addLeftNavigationButtonWithNavigation:_mainNC];
}

- (void)closeAndChange:(UINavigationController *)navigationController
{
    
         [self changeMain:navigationController withRect:_mainNC.view.frame];
         
         [self close];
}

- (void)changeMain:(UINavigationController *)main withRect:(CGRect)rect
{
    [_mainNC popToRootViewControllerAnimated:NO];
    [_mainNC.view removeFromSuperview];
    _mainNC = main;
    
    _mainNC.view.frame = rect;
    
    [self addLeftNavigationButtonWithNavigation:_mainNC];
    
    [self.view addSubview:_mainNC.view];
    [UIView animateWithDuration:0.3 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
    
}

- (void)addLeftNavigationButtonWithNavigation:(UINavigationController *)navigationController
{
    UIViewController *viewController = navigationController.viewControllers[0];
    
    if (_menuButton == nil) {
        _menuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        _menuButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _menuButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        _menuButton.contentEdgeInsets = UIEdgeInsetsMake(23, 15, 0, 0);
        [_menuButton addTarget:self action:@selector(menuChange) forControlEvents:UIControlEventTouchUpInside];
        
        _gestureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, GESTURE_VIEW_WIDTH, _heightMainNC)];
        _gestureView.contentMode = UIViewContentModeLeft;
        
        [self addRecognizers];
    }
    
    [self refreshButtonColor:![_mainNC isEqual:_navigationsArray[0][0]]];
    
    [viewController.view addSubview:_gestureView];
    [viewController.view addSubview:_menuButton];
}

- (void)refreshButtonColor:(BOOL)isWhiteHighlighted
{
    
    UIImage *image = [UIImage imageNamed:@"menuButton"];
    UIImage *imageSelected = [UIImage imageNamed:@"menuSelectedButton"];
    
    if (isWhiteHighlighted) {
        [_menuButton setImage:imageSelected forState:UIControlStateNormal];
        [_menuButton setImage:image forState:UIControlStateHighlighted];
    }
    else {
        [_menuButton setImage:image forState:UIControlStateNormal];
        [_menuButton setImage:imageSelected forState:UIControlStateHighlighted];
    }
    
    CATransition * transition = [CATransition animation];
    transition.duration = 0.3;
    [_menuButton.layer addAnimation:transition forKey:kCATransition];
}

@end

@implementation UIViewController (SidebarController)

-(SidebarController*)sidebarController
{
    UIViewController* parent = self.parentViewController;
    while (parent) {
        if ([parent isKindOfClass:[SidebarController class]]) {
            return (SidebarController*)parent;
        }
        parent = parent.parentViewController;
    }
    return nil;
}

- (void)sideBar:(SidebarController *)sideBar didPresentControllerWithIndexPath:(NSIndexPath *)indexPath
{
}

- (void)sideBar:(SidebarController *)sideBar menuDidChangeState:(BOOL)open
{
}

@end
