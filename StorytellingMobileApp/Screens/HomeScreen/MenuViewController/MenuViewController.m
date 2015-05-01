//
//  MenuViewController.m
//  StorytellingMobileApp
//
//  Created by vaskov on 24.03.14.
//  Copyright (c) 2014 P-Product. All rights reserved.
//

#import "MenuViewController.h"
#import "UIView+Helpers.h"

NSString *kStartNewStoryNotification = @"kStartNewStoryNotification";


@interface MenuViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *createStoryButton;
@property (nonatomic, strong) NSIndexPath *selectedCellWithIndexPath;
@end

@implementation MenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedCellWithIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    self.createStoryButton.layer.cornerRadius = 4;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if ([_delegate respondsToSelector:@selector(didSelectElementWithIndexPath:)]) {
            [_delegate didSelectElementWithIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [_tableView  selectRowAtIndexPath:_selectedCellWithIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (IBAction)didTapCreateStory:(id)sender
{
    if ([_delegate respondsToSelector:@selector(didSelectElementWithIndexPath:)]) {
        [_delegate didSelectElementWithIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kStartNewStoryNotification object:nil];
}

#pragma mark - Publics

- (void)showCreateStoryButton
{
    [UIView animateWithDuration:0.2f animations:^{
        _createStoryButton.left = (self.view.width - _createStoryButton.width) / 2;
    }];
}

- (void)hideCreateStoryButton
{
    _createStoryButton.right = 0;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 3;
    } else if (section == 1) {
        return 2;
    } else if (section == 2) {
        return 1;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section < tableView.numberOfSections - 1 ? 20.0f : 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.boundWidth, 20.0f)];
    view.backgroundColor = [UIColor clearColor];
    
    UIView * separator = [[UIView alloc]initWithFrame:CGRectMake(20.0f, 10.0f, tableView.boundWidth - 40.0f, 0.5f)];
    separator.backgroundColor = [UIColor colorWithWhite:98.f/255 alpha:1];
    
    [view addSubview:separator];
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *identifier = @"SideBarMenuViewCell";
    
    NSMutableArray *titles1 = [@[@[@"All stories", @"Stories I created", @"Stories shared with me"], @[@"My Profile", @"Settings"]] mutableCopy];
    
    NSString *text = [NSString stringWithFormat:@"Version %@.%@", [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleVersion"]];
    [titles1 addObject:@[text]];
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor colorWithWhite:214.f/255 alpha:1];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue Light" size:16];
        cell.separatorInset = UIEdgeInsetsMake(0, 20, 0, 0);
        UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        backgroundView.backgroundColor = [UIColor colorWithWhite:30.f/255 alpha:1];
        cell.selectedBackgroundView = backgroundView;
	}
    
    [cell textLabel].text = titles1[indexPath.section][indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section < tableView.numberOfSections - 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![_selectedCellWithIndexPath isEqual:indexPath]) {
        [tableView deselectRowAtIndexPath:_selectedCellWithIndexPath animated:YES];
        _selectedCellWithIndexPath = indexPath;
    }    
    
    if ([_delegate respondsToSelector:@selector(didSelectElementWithIndexPath:)]) {
        [_delegate didSelectElementWithIndexPath:indexPath];
    }
}

@end
