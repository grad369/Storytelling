//
//  ProfileViewController.m
//  StorytellingMobileApp
//
//  Created by vaskov on 24.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "ProfileViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Settings.h"
#import "UIImageView+Circle.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+Category.h"
#import "DataManager.h"
#import "Model.h"
#import "SidebarController.h"

@interface ProfileViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@property (strong, nonatomic) ALAssetsLibrary* library;
@property (strong, nonatomic) NSArray *assets;
@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setDefaults];
    
    UITapGestureRecognizer* keyboardHideRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    keyboardHideRecogniser.delegate = self;
    keyboardHideRecogniser.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:keyboardHideRecogniser];
    
    NSURL *url = [NSURL URLWithString:SETTINGS.myUser.photo];
    if (url!= nil) {
        UIImage *image = [UIImage imageWithContentsOfFile:url.path];
        self.imageView.image = image;
    }
}

-(void)tapped:(UIGestureRecognizer*)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view endEditing:YES];
    });
}

- (IBAction)photoClick:(id)sender {
    [self showPickerView:YES];
}

- (IBAction)didTapCancelButton:(id)sender
{
    [self showPickerView:NO];
}

#pragma mark - |UITextFieldDelegate|

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    SETTINGS.myUser.name = textField.text;
    [DATA_MANAGER saveContext];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    SETTINGS.myUser.name = textField.text;
    [DATA_MANAGER saveContext];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Privates

- (void)showPickerView:(BOOL)show
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
    imagePicker.allowsEditing = YES;
    
    [self presentViewController:imagePicker
                       animated:YES
                     completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        UIImage *image = info[@"UIImagePickerControllerEditedImage"];
        _imageView.image = image;
        
        NSString *pathToAssetImage = [((NSURL*)info[@"UIImagePickerControllerReferenceURL"]) absoluteString];
        [ALAssetsLibrary assetWithPath:pathToAssetImage result:^(ALAsset *asset) {
            NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSURL *url = [paths firstObject];
            url = [url URLByAppendingPathComponent:asset.defaultRepresentation.filename];
            
            NSData *data = UIImagePNGRepresentation(image);
            BOOL saved = [data writeToURL:url atomically:YES];
            if (saved) {
                SETTINGS.myUser.photo = [url absoluteString];
                [DATA_MANAGER saveContext];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserPhotoChangedNotification object:nil];
                
            } else {
                // TODO: error handling
            }
        } failureBlock:^(NSError *error) {
        } wait:NO];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)setDefaults
{
    _nameTextField.text = SETTINGS.myUser.name;
    _imageView.isCircle = YES;
    
    UIColor *backGroundColor =[UIColor colorWithRed:237/255.0f green:233/255.0f blue:223/255.0f alpha:1];
    self.view.backgroundColor = backGroundColor;
}


@end
