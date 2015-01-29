//
//  PLMainMenuTableViewController.h
//  Pinline
//
//  Created by Richard Allen on 11/17/13.
//

#import <UIKit/UIKit.h>

@interface PLMainMenuTableViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UILabel *allBookmarksCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *toReadBookmarksCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *tagsCountLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *blurView;
@property (nonatomic, retain) IBOutlet UIButton *logOutButton;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *mobilizerLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBookmarkButton;

-(void)updateCountLabels:(NSNotification *)note;
-(void)networkErrorReceived:(NSNotification *)note;
-(void)logOutSuccessful:(NSNotification *)note;

-(void)confirmLogOut;

-(void)logOut;

-(IBAction)logOutButtonPressed:(id)sender;
-(IBAction)logOutButtonTouchDown:(id)sender;
-(IBAction)logOutButtonTouchUpOutside:(id)sender;

-(IBAction)cancelButtonPressed:(id)sender;
-(IBAction)cancelButtonTouchDown:(id)sender;
-(IBAction)cancelButtonTouchUpOutside:(id)sender;

- (IBAction)refresh:(id)sender;
-(void)noChangesNeeded:(NSNotification *)note;

@end