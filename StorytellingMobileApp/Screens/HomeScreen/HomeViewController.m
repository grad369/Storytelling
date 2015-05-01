//
//  HomeViewController.m
//  StorytellingMobileApp
//
//  Created by vaskov on 24.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "HomeViewController.h"

#import <CoreData/CoreData.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+Category.h"
#import "UIImageView+Circle.h"
#import "DataManager.h"
#import "Settings.h"
#import "StoryLayoutController.h"
#import "StoryCollectionCell.h"
#import "AppDelegate.h"
#import "UIView+Helpers.h"
#import "PreviewController.h"
#import "MediaSelectorController.h"
#import "MenuViewController.h"
#import "ALAssetWrapper.h"
#import "RotatingNavigationController.h"
#import "SidebarController.h"
#import "AVPlayerView.h"

#import "AmazonS3Upload.h"
#import "ConvertStoryLocal.h"
#import "NSObject+MTKObserving.h"
#import "keypath.h"

NSString * kHomeViewControllerOpenStoryNotification = @"kHomeViewControllerOpenStoryNotification";
NSString * kHomeViewControllerOpenStoryNotificationStoryURL = @"kHomeViewControllerOpenStoryNotificationStoryURL";

@interface HomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, StoryLayoutControllerDelegate, UIGestureRecognizerDelegate, PreviewControllerDelegate, MediaSelectorControllerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageCollectionViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pageCollectionViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgViewTopContstraint;

@property (weak, nonatomic) IBOutlet UIView *mediaSelectorBg;
@property (weak, nonatomic) IBOutlet UICollectionView *pageCollectionView;
@property (weak, nonatomic) IBOutlet UIView *bottomBgView;
@property (weak, nonatomic) IBOutlet UILabel *startLabel;
@property (weak, nonatomic) IBOutlet UIView *topForPageView;

@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (assign, nonatomic) BOOL openPageCollectionView;

@property (weak, nonatomic) IBOutlet UIView *controlsBG;
@property (strong, nonatomic) UIPanGestureRecognizer* panCollectionView;

@property (strong, nonatomic) NSMutableArray *notifications;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) CGPoint startContentOffset;

@property (nonatomic) CGFloat storyCeedsContentOffset;
@property (weak, nonatomic) IBOutlet UIView *navigationView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *sharingBg;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressConstraint;
@property (weak, nonatomic) IBOutlet UIView *sharingProgressView;
@property (weak, nonatomic) IBOutlet UILabel *sharingLabel;
@property (weak, nonatomic) IBOutlet UIButton *nextBarButton;

@property (weak, nonatomic) IBOutlet UIView *deleteView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deleteViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *deleteDarkView;
@property (strong, nonatomic) IBOutlet UIView *deleteDragView;
@property (weak, nonatomic) IBOutlet UILabel *deleteLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *deleteIconWidthConstraint;

@property (weak, nonatomic) MediaSelectorController *mediaSelectorController;
@end


#define kPageCollectionHeight 360
#define kPages 50

@implementation HomeViewController

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"";
    
    [self registerCollectionView];
    [self addGestureRecognizer];
    [self addNotifications];
    
    [self.sidebarController setMenuDisabled:NO animated:NO];
    MediaSelectorController *controller = [[MediaSelectorController alloc] initWithNibName:@"MediaSelectorController" bundle:nil];
    [self addChildViewController:controller];
    controller.nextBarButton = self.nextBarButton;
    controller.delegate = self;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    controller.view.frame = self.mediaSelectorBg.bounds;
    [self.mediaSelectorBg addSubview:controller.view];
    self.mediaSelectorController = controller;
    
    _startLabel.adjustsFontSizeToFitWidth = YES;
    
    if (self.fetchedResultsController.fetchedObjects.count == 0)
        [self openCollectionView];
    else
        [self closeCollectionView];
}

- (void)dealloc
{
    for (id notification in self.notifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:notification];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self.pageCollectionView.collectionViewLayout invalidateLayout];
    [self.view insertSubview:self.sidebarController.leftMarginGestureView belowSubview:self.pageCollectionView];
    [self scrollViewDidEndDecelerating:self.pageCollectionView];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - |UICollectionViewDataSource|

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.fetchedResultsController.fetchedObjects.count <= 1) {
        return self.fetchedResultsController.fetchedObjects.count;
    }
    
    return self.fetchedResultsController.fetchedObjects.count * kPages;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self pageCollectionWithIndexPath:indexPath];
    return cell;
}

#pragma mark - |UICollectionViewDelegate|

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.openPageCollectionView = YES;
    
    StoryCollectionCell *cell = (StoryCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (self.navigationController.topViewController != self) {
        return;
    }
    
    [self.sidebarController setMenuDisabled:YES animated:YES];
    self.bgViewTopContstraint.constant = self.view.bottom + 16;
    self.navigationBottomConstraint.constant = -CGRectGetHeight(self.navigationView.frame);
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^ {
        [self.view layoutIfNeeded];
        [cell setShowFullScreen:YES];
    } completion:nil];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.startContentOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self updateScrollingPageCollection];
        [self updatePage];
        [self update3DTransform];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateScrollingPageCollection];

    [self updatePage];
    [self update3DTransform];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    void(^block)(NSInteger page, CGFloat delta, BOOL isMain, BOOL isRight) = ^(NSInteger page, CGFloat delta, BOOL isMain, BOOL isRight){
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:page inSection:0];
        StoryCollectionCell *cell = (StoryCollectionCell *)[self.pageCollectionView cellForItemAtIndexPath:indexPath];
        if (cell != nil && self.fetchedResultsController.fetchedObjects.count != 1)
            [cell setDeltaX:delta  mainCell:isMain right:isRight];
    };
    
    CGFloat deltaInPage = ((NSInteger)scrollView.contentOffset.x % 320) / 2;
    BOOL isRight = scrollView.contentOffset.x > _startContentOffset.x;
     
    block(_currentPage, deltaInPage, YES, isRight);
    block(_currentPage - 1, deltaInPage, NO, isRight);
    block(_currentPage + 1, deltaInPage, NO, isRight);
    if (!scrollView.tracking && !scrollView.decelerating) {
        [self updatePage];
    }
    
    [self update3DTransform];
}

- (void)update3DTransform
{
    float center = self.pageCollectionView.contentOffset.x + CGRectGetWidth(self.pageCollectionView.frame) * 0.5;
    for (StoryCollectionCell *cell in self.pageCollectionView.visibleCells) {
        float cellCenter = CGRectGetMidX(cell.frame);
        CATransform3D transform = CATransform3DIdentity;
        transform.m34 = 1.0 / -500;
        float angle = (cellCenter - center) * 0.12 * M_PI / CGRectGetWidth(self.pageCollectionView.frame);
        transform = CATransform3DRotate(transform, angle, 0, 1, 0);
        
        float diff = 1 - fabsf(cellCenter - center) * 0.11 / CGRectGetWidth(self.pageCollectionView.frame);
        transform = CATransform3DScale(transform, diff, diff, 1);
        transform = CATransform3DTranslate(transform, sin(angle) * 50, 0, 0);
        cell.layer.transform = transform;
    }
}

- (void)updatePage
{
    self.currentPage = roundf(self.pageCollectionView.contentOffset.x / 320);
}

- (void)updateScrollingPageCollection
{
    if (self.fetchedResultsController.fetchedObjects.count > 1 &&
        (self.pageCollectionView.contentOffset.x <= CGRectGetWidth(self.pageCollectionView.frame) ||
         self.pageCollectionView.contentOffset.x >= CGRectGetWidth(self.pageCollectionView.frame) * (self.fetchedResultsController.fetchedObjects.count * kPages - 1))) {
            
        self.pageCollectionView.contentOffset = CGPointMake(CGRectGetWidth(self.pageCollectionView.frame) * self.fetchedResultsController.fetchedObjects.count * (kPages / 2), 0);
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.view.bounds.size;
}

#pragma mark - |UIGestureRecognizerDelegate|

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.panCollectionView) {
        if ( [otherGestureRecognizer.view isDescendantOfView:self.mediaSelectorController.collectionView]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.panCollectionView && ![otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        if ( [otherGestureRecognizer.view isDescendantOfView:self.mediaSelectorController.collectionView]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.panCollectionView) {
        // in case the location of touch is within the collection view
        // perform calculations to decide if we need to intercept this gesture and
        // not allow the collection view to scroll
        BOOL inCollection = CGRectContainsPoint(self.mediaSelectorController.collectionView.frame,[gestureRecognizer locationInView:self.mediaSelectorController.collectionView.superview]);
        BOOL onHeader = CGRectContainsPoint(self.controlsBG.frame,[gestureRecognizer locationInView:self.controlsBG.superview]);
        if (inCollection && NO == onHeader) {
            CGPoint v = [self.panCollectionView velocityInView:self.mediaSelectorController.collectionView];
            
            BOOL shouldBegin = (self.bottomBgView.frame.origin.y > 0);
            shouldBegin |= ((v.y > 0) && (self.mediaSelectorController.collectionView.contentOffset.y <= -self.mediaSelectorController.collectionView.contentInset.top));
            
            return shouldBegin;
        }
    }
    return YES;
}

#pragma mark - |NSFetchedResultsControllerDelegate|

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_pageCollectionView reloadData];
    if (!self.openPageCollectionView) {
        [self movingBottomBgViewToTop:controller.fetchedObjects.count == 0 animated:YES];
    }
    
    if (self.fetchedResultsController.fetchedObjects.count > 0)
        [_pageCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

#pragma mark - Actions

- (IBAction)didTapNextButton:(id)sender
{
    if (self.bgViewTopContstraint.constant > 0) {
        [self movingBottomBgViewToTop:YES animated:YES completion:^{
            [self.mediaSelectorController didTapNextButton:sender];
        }];
    } else {
        [self.mediaSelectorController didTapNextButton:sender];
    }
}

- (void)closeCollectionView
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[0];
    NSInteger countObjects = [sectionInfo.objects count];
    
    if (countObjects == 0 || self.openPageCollectionView)
        return;
    [self movingBottomBgViewToTop:NO animated:NO];
}

- (void)openCollectionView
{
    [self movingBottomBgViewToTop:YES animated:NO];
}

- (IBAction)didTapCloseButton
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentPage inSection:0];
    StoryCollectionCell *cell = (StoryCollectionCell *)[self.pageCollectionView cellForItemAtIndexPath:indexPath];
    
    self.navigationBottomConstraint.constant = 0;
    
    self.openPageCollectionView = NO;
    [self.sidebarController setMenuDisabled:NO animated:YES];
    
    self.bgViewTopContstraint.constant = kPageCollectionHeight;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.view layoutIfNeeded];
        [cell setShowFullScreen:NO];
    } completion:nil];
}

- (IBAction)didTapShareButton:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentPage inSection:0];
    StoryCollectionCell *cell = (StoryCollectionCell *)[self.pageCollectionView cellForItemAtIndexPath:indexPath];
    PreviewController *previewC = [cell controller];
    UIButton *shareButton = sender;
    
    if (1 == shareButton.tag) {
        shareButton.tag = 0;
        shareButton.selected = NO;
        [previewC.processingQueue cancelAllOperations];
        // for the case when it was passed
        [previewC.convertOperation cancel];
        self.sharingBg.hidden = YES;
        self.sharingBg.alpha = 1;
        [UIView animateWithDuration:0.3 animations:^{
            self.closeButton.alpha = 1;
            self.sharingBg.alpha = 0;
        }];
    }
    else {
        if ([previewC.story.shared boolValue]) {
            NSURL* shareURL = previewC.story.shareURL;
            [previewC showActivityControllerWithUrl:shareURL completion:nil];
        } else {
            shareButton.selected = YES;
            shareButton.tag = 1;
            [self.view layoutIfNeeded];
            [self uploadStory];
        }
    }
}

#pragma mark - Privates

- (void)registerCollectionView
{
    [self.pageCollectionView registerNib:[UINib nibWithNibName:@"StoryCollectionCell" bundle:nil]
              forCellWithReuseIdentifier:@"StoryCollectionCell"];
}

- (void)addGestureRecognizer
{
    self.panCollectionView = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCollectionView:)];
    self.panCollectionView.delegate = self;
    [self.bottomBgView addGestureRecognizer:self.panCollectionView];
}

-(void)panCollectionView:(UIPanGestureRecognizer*)recognizer
{
    static CGPoint startLocation;
    static CGFloat startConstant;
    CGPoint location = [recognizer locationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerViewStopPlayingVideoNotification object:nil];
        startLocation = location;
        startConstant = self.bgViewTopContstraint.constant;
        
        CGPoint co = self.mediaSelectorController.collectionView.contentOffset;
        self.storyCeedsContentOffset = MAX(0,co.y + self.mediaSelectorController.collectionView.contentInset.top);
        
        //to stop the current scroll
        [self.mediaSelectorController.collectionView setContentOffset:co animated:NO];
    }
    
    CGFloat delta = location.y - startLocation.y;
    CGFloat newConstant = delta + startConstant;
    newConstant = MIN(newConstant, kPageCollectionHeight);
    newConstant = MAX(newConstant, 0.0f);
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
        [self setNextBarButtonVisible:NO];
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self redrawViews:newConstant/kPageCollectionHeight];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint v = [recognizer velocityInView:self.view];
        if ([self.fetchedResultsController.fetchedObjects count]>0) {
            BOOL toTop = v.y < -50 || (v.y < 50 && newConstant/kPageCollectionHeight < 0.5);
            CGFloat distance = toTop ? newConstant : kPageCollectionHeight - newConstant;
            
            CGFloat initialVelocity = distance > 10 ? v.y / distance : 0;
            initialVelocity = MIN(40, fabsf(initialVelocity));
            
            [UIView animateWithDuration:0.4f
                                  delay:0
                 usingSpringWithDamping:toTop ? 0.7 : 10
                  initialSpringVelocity:initialVelocity
                                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                             animations:^ {
                [self redrawViews:(toTop ? 0 : 1)];
                [self.sidebarController refreshButtonColor:toTop];
            } completion:^(BOOL finished) {
                if (finished && recognizer.state == UIGestureRecognizerStatePossible) {
                    [self redrawViews:(toTop ? 0 : 1)];
                    
                    if (!toTop)
                        [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerViewStartPlayingVideoNotification object:nil];
                }
                
                [self setNextBarButtonVisible:toTop];
            }];
        }
    }
}

- (void)setNextBarButtonVisible:(BOOL)visible
{
    if (visible) {
        self.nextBarButton.hidden = NO;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.nextBarButton.alpha = visible;
    } completion:^(BOOL finished) {
        if (finished) {
            self.nextBarButton.hidden = !visible;
        }
    }];
}

- (void)movingBottomBgViewToTop:(BOOL)toTop animated:(BOOL)animated
{
    [self movingBottomBgViewToTop:toTop animated:animated completion:nil];
}

- (void)movingBottomBgViewToTop:(BOOL)toTop animated:(BOOL)animated completion:(void(^)())completion
{
    if (NO == toTop && [self.mediaSelectorController.collectionView numberOfSections] > 0 && [self.mediaSelectorController.collectionView numberOfItemsInSection:0] > 0) {
        [self.mediaSelectorController.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:animated];
    }
    self.storyCeedsContentOffset = 0;
    if (!animated) {
        [self redrawViews:(toTop ? 0 : 1)];
        [self.sidebarController refreshButtonColor:toTop];
        [self setNextBarButtonVisible:toTop];
        if (completion) {
            completion();
        }
        return;
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        [self redrawViews:(toTop ? 0 : 1)];
    } completion:^(BOOL finished) {
        [self.sidebarController refreshButtonColor:toTop];
        [self setNextBarButtonVisible:toTop];
        if (completion) {
            completion();
        }
    }];
}

- (void)redrawViews:(CGFloat)delta
{
    if ([[self.fetchedResultsController fetchedObjects] count] == 0)
        delta = 0;
    
    self.bgViewTopContstraint.constant = kPageCollectionHeight * delta;
    
    CGFloat pageCollectionDisplacement = 0.25 * kPageCollectionHeight * (delta -1);
    self.pageCollectionViewTopConstraint.constant = pageCollectionDisplacement;
    self.pageCollectionViewBottomConstraint.constant = -pageCollectionDisplacement;
    
    CGPoint co = self.mediaSelectorController.collectionView.contentOffset;
    co.y = MAX(- self.mediaSelectorController.collectionView.contentInset.top, self.storyCeedsContentOffset * (1-delta) - self.mediaSelectorController.collectionView.contentInset.top);
    [self.mediaSelectorController.collectionView setContentOffset:co animated:NO];
    
    // the minimum alpha
    CGFloat const maxAlpha = 0.7;
    CGFloat alpha = ((1-delta) * maxAlpha);
    
    alpha = MAX(0.0f, alpha);
    alpha = MIN(maxAlpha
                , alpha);
    
    self.topForPageView.alpha = alpha;
   
    float min = (CGRectGetWidth(self.startLabel.bounds) - 60) / CGRectGetWidth(self.startLabel.bounds);
    float scale = min + (1 - min) * delta;
    UIFont *font = nil;
    
    if (delta <= 0) {
        font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:24];
    } else {
        font = [UIFont fontWithName:@"HelveticaNeue-Light" size:26];
    }
    self.startLabel.font = font;
    self.startLabel.transform = CGAffineTransformMakeScale(scale, scale);
    [self.view layoutIfNeeded];
}

- (void)addNotifications
{
    self.notifications = [NSMutableArray array];
    __weak typeof (self) weakSelf = self;
    
    [self.notifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:kUserPhotoChangedNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf.pageCollectionView reloadData];
    }]];
    
    [self.notifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:kDidUploadStoryNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf.mediaSelectorController resetStory];
        [weakSelf closeCollectionView];
    }]];
    
    [self.notifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:kStartNewStoryNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self movingBottomBgViewToTop:YES animated:YES];
    }]];
    
    [self.notifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:kHomeViewControllerOpenStoryNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        typeof(self) me = weakSelf;
        if (nil == me) {
            return;
        }
        if (me.navigationController.topViewController == me) {
            [me presentStoryWithURL:note.userInfo[kHomeViewControllerOpenStoryNotificationStoryURL]];
        }
    }]];
    
    [self.notifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:SidebarControllerSelectedMenuNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[0];
        NSInteger countObjects = [sectionInfo.objects count];
        countObjects>0 ? [weakSelf closeCollectionView] : [weakSelf openCollectionView];
    }]];
    
    [self.notifications addObject:[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf clearViews];
    }]];
}

- (StoryCollectionCell *)pageCollectionWithIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row % self.fetchedResultsController.fetchedObjects.count;
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:index inSection:indexPath.section];
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:newIndexPath];
    
    StoryCollectionCell *cell = [_pageCollectionView dequeueReusableCellWithReuseIdentifier:@"StoryCollectionCell"
                                                                               forIndexPath:indexPath];
    cell.controller.delegate = self;
    cell.controller.layoutController.delegate = self;
    cell.controller.layoutController.dragView = self.deleteDragView;
    cell.story = (Story *)object;
    cell.showFullScreen = self.openPageCollectionView;
    [self addChildViewController:cell.controller];
    return cell;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Story class])];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DATA_MANAGER.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)presentStoryWithURL:(NSURL*)storyURL
{
    // WARNING:
    // a naive approach with bad performance given thousands of stories
    NSUInteger index = 0;
    for (Story* story in self.fetchedResultsController.fetchedObjects) {
        if ([storyURL.host isEqualToString:story.id]) {
            NSIndexPath* path = [NSIndexPath indexPathForItem:index inSection:0];
            [self.pageCollectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
            
            // after the scroll is finished
            double delayInSeconds = 0.25;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self collectionView:self.pageCollectionView didSelectItemAtIndexPath:path];
            });
        }
        index++;
    }
}

- (void)sideBar:(SidebarController *)sideBar didPresentControllerWithIndexPath:(NSIndexPath *)indexPath
{
    NSPredicate *predicate = nil;
    if (indexPath.row == 1) {
        predicate = [NSPredicate predicateWithFormat:@"user == %@", SETTINGS.myUser];
    } else if (indexPath.row == 2) {
        predicate = [NSPredicate predicateWithFormat:@"user != %@", SETTINGS.myUser];
    }
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    [self.pageCollectionView reloadData];
}

- (void)sideBar:(SidebarController *)sideBar menuChangeState:(BOOL)open
{
    if (NO == open) {
        [self.view insertSubview:self.sidebarController.leftMarginGestureView belowSubview:self.pageCollectionView];
    }
}

- (void)clearViews
{
    [self closeCollectionView];
    [self didTapCloseButton];
    [self.mediaSelectorController resetStory];
    [self.pageCollectionView reloadData];
}

#pragma mark - Uploading

- (void)uploadStory
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentPage inSection:0];
    StoryCollectionCell *cell = (StoryCollectionCell*)[self.pageCollectionView cellForItemAtIndexPath:indexPath];
    PreviewController *previewC = [cell controller];
    previewC.layoutController.story = cell.story;
    
    previewC.layoutController.view.userInteractionEnabled = NO;
    self.sharingBg.hidden = NO;
    self.sharingBg.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.closeButton.alpha = 0;
        self.sharingBg.alpha = 1;
    }];
    
    [previewC.story.managedObjectContext save:nil];
    [DATA_MANAGER saveContext];
    
    previewC.processingQueue = [NSOperationQueue new];
    
    AmazonS3Upload *upload;
    
    if (nil == previewC.convertOperation || previewC.convertOperation.isCancelled) {
        previewC.convertOperation = [[ConvertStoryLocal alloc] initWithStory:previewC.story];
        [previewC.processingQueue addOperation:previewC.convertOperation];
    }
    
    upload = [[AmazonS3Upload alloc] initWithStory:previewC.story];
    [upload addDependency:previewC.convertOperation];
    
    [previewC.processingQueue addOperation:upload];
    
    __weak typeof (self)weakSelf = self;
    
    void(^progressBlock)(float progress) = ^(float progress) {
        weakSelf.progressConstraint.constant = (1 - progress) * CGRectGetWidth(weakSelf.sharingProgressView.frame);
    };
    
    previewC.convertOperation.progressBlock = progressBlock;
    upload.progressBlock = progressBlock;
    
    [self observeObject:upload property:@keypath(upload.isExecuting) withBlock:^(__typeof(self) self, id object, id old, id newVal) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* text = nil;
            if ([newVal boolValue]) {
                text = @"Uploading...";
            }
            else {
                if (previewC.convertOperation.isExecuting) {
                    text = @"Converting...";
                }
                else {
                    text = @"Completed";
                }
                
            }
            weakSelf.sharingLabel.text = text;
            weakSelf.progressConstraint.constant = CGRectGetWidth(weakSelf.sharingProgressView.frame);
        });
    }];
    
    [upload setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([previewC.delegate respondsToSelector:@selector(previewControllerDidTapShare:)]) {
                [previewC.delegate previewControllerDidTapShare:previewC];
            }
            
            [previewC.story.managedObjectContext save:nil];
            [DATA_MANAGER saveContext];
            
            NSURL* shareURL = previewC.story.shareURL;
            if (nil == shareURL) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [previewC showActivityControllerWithUrl:shareURL completion:^{
                    [previewC.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }];
            }
            
            previewC.layoutController.view.userInteractionEnabled = YES;
            self.shareButton.tag = 0;
            self.shareButton.selected = NO;
            
            [UIView animateWithDuration:0.3 animations:^{
                self.closeButton.alpha = 1;
                self.sharingBg.alpha = 0;
            } completion:^(BOOL finished) {
                self.sharingBg.hidden = YES;
            }];
        });
    }];
}

#pragma mark - MediaSelectorController Delegate
- (void)mediaSelectorControllerDidUpdateStory:(MediaSelectorController *)controller
{
    if (self.bgViewTopContstraint.constant > 0) {
        [self movingBottomBgViewToTop:YES animated:YES];
    }
}

#pragma mark - StoryLayoutController Delegate

- (void)layoutController:(StoryLayoutController *)controller didDeleteMediaAtIndex:(NSInteger)index;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger index = self.currentPage % self.fetchedResultsController.fetchedObjects.count;
        [DATA_MANAGER.managedObjectContext deleteObject:self.fetchedResultsController.fetchedObjects[index]];
        [DATA_MANAGER saveContext];
    });
    
    [self layoutControllerDidExitFromDeleteZone:controller];
}

- (void)layoutControllerDidBeginEdit:(StoryLayoutController *)controller
{
    self.deleteViewBottomConstraint.constant = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.deleteDarkView.alpha = 1;
        [self.view layoutIfNeeded];
    }];
}

- (void)layoutControllerDidEndEdit:(StoryLayoutController *)controller
{
    self.deleteViewBottomConstraint.constant = -CGRectGetHeight(self.deleteView.frame);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.deleteDarkView.alpha = 0;
        [self.view layoutIfNeeded];
    }];
}

- (void)layoutControllerDidEnterToDeleteZone:(StoryLayoutController *)controller
{
    self.deleteIconWidthConstraint.constant = 50;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    self.deleteLabel.text = @"remove";
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    [self.deleteLabel.layer addAnimation:transition forKey:@"transition"];
}

- (void)layoutControllerDidExitFromDeleteZone:(StoryLayoutController *)controller
{
    self.deleteIconWidthConstraint.constant = 40;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    self.deleteLabel.text = @"drag here to remove";
    
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    [self.deleteLabel.layer addAnimation:transition forKey:@"transition"];
}

@end
