//
//  SHMenuDelegate.h
//  MCV
//
//  Created by vaskov on 12/13/12.
//  Copyright 2012 NIX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MenuViewControllerDelegate <NSObject>
@optional
- (void)didSelectElementWithIndexPath:(NSIndexPath *)indexPath;
@end