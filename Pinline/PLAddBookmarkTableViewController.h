//
//  PLAddBookmarkTableViewController.h
//  Pinline
//
//  Created by Richard Allen on 12/15/13.
//

#import <UIKit/UIKit.h>
#import "Bookmark.h"

@interface PLAddBookmarkTableViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, UIWebViewDelegate>
{
    UITextField *selectedTextField;
    BOOL changesMade;
    BOOL saved;
    UIWebView *webview;
}

@property (strong, nonatomic) Bookmark *bookmark;
@property (weak, nonatomic) IBOutlet UITextField *descLabel;
@property (weak, nonatomic) IBOutlet UITextField *urlLabel;
@property (weak, nonatomic) IBOutlet UISwitch *sharedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *toReadSwitch;
@property (weak, nonatomic) IBOutlet UITextField *tagView;
@property (weak, nonatomic) IBOutlet UITextView *extendedView;

-(IBAction)dismissKeyboard:(id)sender;
-(IBAction)saveButtonPressed:(id)sender;
-(IBAction)cancelButtonPressed:(id)sender;
-(IBAction)changeMade:(id)sender;

-(void)editSuccessful:(NSNotification *)note;

-(void)getPageTitleFromURLString:(NSString *)urlString;

@end
