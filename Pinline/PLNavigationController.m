//
//  PLNavigationController.m
//  Pinline
//
//  Created by Richard Allen on 12/15/13.
//

#import "PLNavigationController.h"
#import "PLWebViewController.h"

@interface PLNavigationController ()

@end

@implementation PLNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)shouldAutorotate
{
    BOOL allowRotation = NO;
    
    for (UIViewController *vc in [self childViewControllers])
    {
        if ([vc isKindOfClass:[PLWebViewController class]])
        {
            allowRotation = YES;
        }
    }
    
    return allowRotation;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self preferredStatusBarStyle];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editSuccessful:) name:@"BookmarkAddedSuccessfully" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkErrorReceived:) name:@"NetworkOperationFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkTooSoonReceived:) name:@"NetworkOperationTooSoon" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)editSuccessful:(NSNotification *)note
{
    [TSMessage showNotificationWithTitle:[NSString stringWithFormat:@"Saved"]
                                subtitle:[NSString stringWithFormat:@"Bookmark saved."]
                                    type:TSMessageNotificationTypeSuccess];
}

-(void)networkErrorReceived:(NSNotification *)note
{
    [TSMessage showNotificationWithTitle:[NSString stringWithFormat:@"Network Error"]
                                subtitle:[NSString stringWithFormat:@"Unable to connect to Pinboard."]
                                    type:TSMessageNotificationTypeError];
}

-(void)networkTooSoonReceived:(NSNotification *)note
{
    //[TSMessage showNotificationWithTitle:[NSString stringWithFormat:@"Hold On a Minute"]
    //                            subtitle:[NSString stringWithFormat:@"Pinboard requests limit reached. Try again in a minute."]
    //                                type:TSMessageNotificationTypeWarning];
}


@end
