//
//  PLLoginTableViewController.h
//  Pinline
//
//  Created by Richard Allen on 12/7/13.
//  Copyright (c) 2013 TinyShop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLLoginTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

-(void)authApproved:(NSNotification *)notification;
-(void)authFailed:(NSNotification *)notification;
-(void)networkErrorReceived:(NSNotification *)note;

@end
