//
//  StoryEditorController.m
//  StorytellingMobileApp
//
//  Created by Konstantin Shulika on 24.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "StoryEditorController.h"
#import "StoryEditorCollectionCell.h"
#import "StoryLayout.h"
#import "PreviewController.h"
#import "DataManager.h"
#import "Settings.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "NestedScrollView.h"
#import "TestGestureRecognizer.h"
#import "ConvertStoryLocal.h"
#import "ModalPresentAnimator.h"

@interface StoryEditorController () <UITextFieldDelegate, UITextViewDelegate, StoryLayoutControllerDelegate, PreviewControllerDelegate, UIViewControllerTransitioningDelegate>
@property (weak, nonatomic) IBOutlet NestedScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *textViewPlaceholder;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *textViewSizeLayoutLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textViewSizeLayoutLabelHeigthConstraint;

@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIView *tapView;

@property (weak, nonatomic) IBOutlet UIView *layoutView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIImageView *textViewBg;
@property (weak, nonatomic) IBOutlet UIView *navigationView;

@property (weak, nonatomic) IBOutlet UIView *deleteView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deleteViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *inputsBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *deleteDarkView;
@property (strong, nonatomic) IBOutlet UIView *deleteDragView;
@property (weak, nonatomic) IBOutlet UIImageView *deleteIcon;
@property (weak, nonatomic) IBOutlet UILabel *deleteLabel;
@property (weak, nonatomic) IBOutlet UIImageView *topShadow;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *deleteIconWidthConstraint;

@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *previewBarButton;

@property (strong, nonatomic) NSArray *layouts;
@property (nonatomic) NSInteger currentLayout;
@property (strong, nonatomic) PreviewController *previewController;
@property (strong, nonatomic) NSManagedObjectContext *processingContext;
@property (strong, nonatomic) NSOperationQueue* processingQueue;
@property (strong, nonatomic) ConvertStoryLocal* convertOperation;
@end


@implementation StoryEditorController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.contentInset = UIEdgeInsetsMake(62, 0, 0, 0);
    
    self.deleteIconWidthConstraint.constant = 40;
    
    self.textViewBg.image = [self.textViewBg.image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"StoryEditorCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"Cell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    __weak typeof (self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf dismissViewControllerAnimated:NO completion:nil];
        [weakSelf.navigationController popToRootViewControllerAnimated:NO];
    }];
    
    self.layouts = [StoryLayout layoutsWithItemsCount:self.story.media.count];
    [self makeStory];
    
    self.previewController = [[PreviewController alloc] initWithNibName:@"PreviewController" bundle:nil];
    self.previewController.view.frame = self.layoutView.bounds;
    self.previewController.showFromEditor = YES;
    self.previewController.layoutController.dragView = self.deleteDragView;
    self.previewController.layoutController.canEdit = YES;
    self.previewController.layoutController.editMode = StoryLayoutControllerEditModeZoom;
    self.previewController.layoutController.showVideo = NO;
    self.previewController.layoutController.delegate = self;
    self.previewController.story = self.story;
    [self.layoutView addSubview:self.previewController.view];
    [self selectCurrentLayoutAnimated:NO];
    
    self.scrollView.noTouchCancelInThisView = self.layoutView;
    
    TestGestureRecognizer* tgr = [[TestGestureRecognizer alloc] initWithTarget:self action:@selector(test)];
    [self.layoutView addGestureRecognizer:tgr];
    
    self.navigationItem.rightBarButtonItem = self.previewBarButton;
    
    self.textViewPlaceholder.hidden = self.textView.text.length > 0;
    
}

-(void)dealloc
{
    [self.processingQueue cancelAllOperations];
}

-(void)test
{
    [self.scrollView scrollRectToVisible:self.layoutView.frame animated:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [self.previewController.layoutController saveFrames];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.swipeGestureRecognizer.enabled = YES;
    self.scrollView.scrollEnabled = NO;
    self.tapView.userInteractionEnabled = YES;
    
    CGRect frame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, frame.size.height, 0);
    
    CGPoint labelOnBackground = [self.inputsBackgroundView convertPoint:self.textViewSizeLayoutLabel.frame.origin fromView:self.textViewSizeLayoutLabel.superview];
    
    CGFloat height = CGRectGetHeight(self.view.frame) - self.scrollView.contentInset.top - frame.size.height - labelOnBackground.y - 25;
    
    self.textViewSizeLayoutLabelHeigthConstraint.constant = height;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.swipeGestureRecognizer.enabled = NO;
    self.scrollView.scrollEnabled = YES;
    self.tapView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, 0, 0);
        [self.view layoutIfNeeded];
    }];
}

- (void)scrollToInputsViewVisible
{
    CGRect frame = [self.scrollView convertRect:self.inputsBackgroundView.frame fromView:self.inputsBackgroundView.superview];
    [UIView animateWithDuration:0.3 animations:^{
        [self.scrollView scrollRectToVisible:frame animated:NO];
    }];
}

- (void)selectCurrentLayoutAnimated:(BOOL)animated
{
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentLayout inSection:0] animated:animated scrollPosition:UICollectionViewScrollPositionNone];
    [self.scrollView scrollRectToVisible:self.layoutView.frame animated:animated];
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.previewController.layoutController setLayout:self.layouts[self.currentLayout]];
        } completion:nil];
    } else {
        [self.previewController.layoutController setLayout:self.layouts[self.currentLayout]];
    }
}

- (IBAction)handleSwipeGesture:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)didTapPreviewButton:(id)sender
{
    if (self.textField.text.length == 0) {
    } else {
        self.story.title = [self.textField.text copy];
    }
    
    self.story.text = [self.textView.text copy];
    [self.previewController.layoutController saveFrames];
    
    PreviewController *controller = [[PreviewController alloc] initWithNibName:@"PreviewController" bundle:nil];
    controller.transitioningDelegate = self;
    controller.modalPresentationStyle = UIModalPresentationCustom;
    controller.story = self.story;
    controller.delegate = self;
    controller.convertOperation = self.convertOperation;
    [self presentViewController:controller animated:YES completion:nil];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationView.alpha = 0;
    }];
}

- (IBAction)didTapBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)makeStory
{
    self.textField.text = self.story.title;
    self.textView.text = self.story.text;
    
    NSInteger layoutIndex = [[self.layouts valueForKey:@"name"] indexOfObject:self.story.layoutType ?: @""];
    self.currentLayout = NSNotFound == layoutIndex ? 0 : layoutIndex;
    self.story.layoutType = nil;
    
    if (SETTINGS.earlyCompress) {
        self.convertOperation = [[ConvertStoryLocal alloc] initWithStory:self.story];
        self.processingQueue = [NSOperationQueue new];
        [self.processingQueue addOperation:self.convertOperation];
    }
}

#pragma mark - Collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.layouts.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    StoryLayout *layout = self.layouts[indexPath.row];
    StoryEditorCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.imageView.image = layout.image;
    cell.imageView.highlightedImage = layout.selectedImage;
    return cell;
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentLayout = indexPath.row;
    StoryLayout *layout = self.layouts[self.currentLayout];
    self.story.layoutType = layout.name;
    [self selectCurrentLayoutAnimated:YES];
}

#pragma mark - ScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.topShadow.alpha = MAX(MIN((scrollView.contentOffset.y + scrollView.contentInset.top) * 0.1, 1), 0);
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToInputsViewVisible];
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.story.title = self.textField.text;
}

#pragma mark - UITextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self scrollToInputsViewVisible];
    self.textViewPlaceholder.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.textViewPlaceholder.hidden = textView.text.length > 0;
    self.story.text = self.textView.text;
}

-(void)textViewDidChangeSelection:(UITextView *)textView
{
    UITextRange* tr = textView.selectedTextRange;
    if (tr.empty) {
        CGRect textRect = [self.textView caretRectForPosition:tr.start];
        [self.textView scrollRectToVisible:textRect animated:YES];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString* newText = [self.textView.text stringByReplacingCharactersInRange:range withString:text];
    self.textViewSizeLayoutLabel.text = newText;
    
    [self.inputsBackgroundView setNeedsLayout];
    [self.inputsBackgroundView layoutIfNeeded];
    
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
    }
    
    [self scrollToInputsViewVisible];
    
    return YES;
}

#pragma mark - StoryLayoutController Delegate

- (void)layoutController:(StoryLayoutController *)controller didDeleteMediaAtIndex:(NSInteger)index;
{
    NSMutableOrderedSet *set = [self.story.media mutableCopy];
    [set removeObjectAtIndex:index];
    self.story.media = set;
    
    self.layouts = [StoryLayout layoutsWithItemsCount:self.story.media.count];
    [self.collectionView reloadData];
    
    self.currentLayout = 0;
    [self selectCurrentLayoutAnimated:YES];
    [self layoutControllerDidExitFromDeleteZone:self.previewController.layoutController];
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
    
    if ([self.delegate respondsToSelector:@selector(storyEditorController:didUpdateStory:)]) {
        [self.delegate storyEditorController:self didUpdateStory:self.story];
    }
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

#pragma mark - PreviewController delegate

- (void)previewControllerDidTapShare:(PreviewController *)controller
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)previewControllerDidTapClose:(PreviewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [UIView animateWithDuration:0.3 animations:^{
        self.navigationView.alpha = 1;
    }];
}


#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(PreviewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    ModalPresentAnimator *animator = [[ModalPresentAnimator alloc] init];
    animator.presenting = YES;
    return animator;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(PreviewController *)dismissed
{
    ModalPresentAnimator *animator = [[ModalPresentAnimator alloc] init];
    return animator;
}

@end
