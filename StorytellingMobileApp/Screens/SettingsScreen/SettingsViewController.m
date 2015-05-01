//
//  SettingsViewController.m
//  StorytellingMobileApp
//
//  Created by vaskov on 26.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "SettingsViewController.h"
#import "Settings.h"
#import "AmazonS3Defines.h"

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UITapGestureRecognizer *keyboardHideRecogniser;
@end

@implementation SettingsViewController

#pragma mark - View life

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIColor *backGroundColor =[UIColor colorWithRed:237/255.0f green:233/255.0f blue:223/255.0f alpha:1];
    self.view.backgroundColor = backGroundColor;    
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 8;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *titles = @[@"Big Compression", @"Small Compression", @"Early Compression", @"Big Image Size", @"Small Image size", @"Cache story media", @"Layout grid", @"Auto-play multiple videos"];
    
    return titles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self titlesForSection:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifierDefault = @"SettingsMenuViewCell", *identifierTextField = @"TextFieldCell";
	static UITextField *textField;
    BOOL isLastSection = NO;
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:isLastSection ? identifierTextField : identifierDefault];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:(isLastSection) ? identifierTextField : identifierDefault];
        UIColor *backGroundColor =[UIColor colorWithRed:237/255.0f green:233/255.0f blue:223/255.0f alpha:1];
        cell.backgroundColor = backGroundColor;
        
        if (isLastSection) {
            textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 15, 300, 25)];
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.delegate = self;
            [cell addSubview:textField];
            cell.backgroundColor = [UIColor lightGrayColor];
        }
	}
    
    [cell textLabel].text = [self titlesForSection:indexPath.section][indexPath.row];
    cell.accessoryType = [self accessoryTypeForCellWithIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self changeTypeToSettings:indexPath];
    [tableView reloadData];
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Privates

- (NSArray *)titlesForSection:(NSInteger)section
{
    NSArray *titles = nil;
    if (section == 0 || section == 1) {
        titles = @[@"Low", @"Medium", @"High", @"640x480", @"960x540", @"1280x720"];
    }
    else if (section == 2) {
        titles = @[@"NO", @"YES"];
    }
    else if (section == 3 || section == 4) {
        titles = @[@"0.3 MP (~640x480)", @"0.7 MP (~1024x768)", @"1 MP (~1280x800)", @"2 MP (~ 1920x1080)"];
    }
    else if (section == 5) {
        titles = @[@"NO", @"YES"];
    }
    else if (section == 6) {
        titles = @[@"OFF", @"ON"];
    }
    else {
        titles = @[@"Simultaneous", @"Synchronized"];
    }
    
    return titles;
}

- (UITableViewCellAccessoryType)accessoryTypeForCellWithIndexPath:(NSIndexPath *)indexPath
{    
    BOOL answered;
    
    switch (indexPath.section) {
        case 0:
            answered = SETTINGS.bigCompressVideoType == indexPath.row;
        break;
            
        case 1:
            answered = SETTINGS.smallCompressVideoType == indexPath.row;
        break;
            
        case 2:
            answered = SETTINGS.earlyCompress == indexPath.row;
        break;
            
        case 3:
            answered = SETTINGS.bigImageSizeType == indexPath.row;
        break;
        
        case 4:
            answered = SETTINGS.smallImageSizeType == indexPath.row;
        break;
            
        case 5:
            answered = SETTINGS.cacheStoryMedia == indexPath.row;
        break;
            
        case 6:
            answered = SETTINGS.storyLayoutGrid == indexPath.row;
        break;
            
        case 7:
            answered = SETTINGS.videosType == indexPath.row;
        break;
    }
    
    return answered ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)changeTypeToSettings:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            SETTINGS.bigCompressVideoType = indexPath.row;
        break;
            
        case 1:
            SETTINGS.smallCompressVideoType = indexPath.row;
        break;
            
        case 2:
            SETTINGS.earlyCompress = indexPath.row;
        break;
            
        case 3:
            SETTINGS.bigImageSizeType = indexPath.row;
        break;
            
        case 4:
            SETTINGS.smallImageSizeType = indexPath.row;
        break;
            
        case 5:
            SETTINGS.cacheStoryMedia = indexPath.row;
        break;
            
        case 6:
            SETTINGS.storyLayoutGrid = indexPath.row;
        break;
            
        case 7:
            SETTINGS.videosType = indexPath.row;
        break;
    }
}

@end
