//
//  PLEditTableViewController.h
//  Pinline
//
//  Created by Richard Allen on 11/18/13.
//

#import <UIKit/UIKit.h>
#import "Bookmark.h"

@interface PLEditTableViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate>
{
    UITextField *selectedTextField;
    BOOL changesMade;
}

@property (weak, nonatomic) Bookmark *bookmarkToEdit;
@property (weak, nonatomic) IBOutlet UITextField *descLabel;
@property (weak, nonatomic) IBOutlet UITextField *urlLabel;
@property (weak, nonatomic) IBOutlet UISwitch *sharedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *toReadSwitch;
@property (weak, nonatomic) IBOutlet UITextField *tagView;
@property (weak, nonatomic) IBOutlet UITextView *extendedView;

-(IBAction)dismissKeyboard:(id)sender;
-(IBAction)saveButtonPressed:(id)sender;
-(IBAction)changeMade:(id)sender;

-(void)editSuccessful:(NSNotification *)note;
-(void)networkErrorReceived:(NSNotification *)note;

@end
