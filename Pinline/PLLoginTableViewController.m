//
//  PLLoginTableViewController.m
//  Pinline
//
//  Created by Richard Allen on 12/7/13.
//  Copyright (c) 2013 TinyShop. All rights reserved.
//

#import "PLLoginTableViewController.h"

@interface PLLoginTableViewController ()

@end

@implementation PLLoginTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkErrorReceived:) name:@"NetworkOperationFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authApproved:) name:@"AuthApprovedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authFailed:) name:@"AuthFailedNotification" object:nil];
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"APIToken"] != nil)
    {
        [self performSegueWithIdentifier:@"pushToListViewSegue" sender:self];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)authApproved:(NSNotification *)notification
{
    [self performSegueWithIdentifier:@"pushToListViewSegue" sender:self];
}

-(void)authFailed:(NSNotification *)notification
{
    [_userNameField resignFirstResponder];
    [_passwordField resignFirstResponder];
    [TSMessage showNotificationInViewController:self title:@"Whoops!" subtitle:@"Either your username or password was incorrect." type:TSMessageNotificationTypeError];
    
}

#pragma mark -- Text Field Delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{

}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == _userNameField)
    {
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField)
    {
        [self login];
    }
    
    return YES;
}

-(void)networkErrorReceived:(NSNotification *)note
{
    [_userNameField resignFirstResponder];
    [_passwordField resignFirstResponder];
    
    [TSMessage showNotificationInViewController:self title:@"Network Error" subtitle:@"Unable to connect to Pinboard" type:TSMessageNotificationTypeError];
}

- (void)login
{
    [[Pincore sharedManager] authorizeUser:_userNameField.text withPassword:_passwordField.text];
}

@end