//
//  PLEditTableViewController.m
//  Pinline
//
//  Created by Richard Allen on 11/18/13.
//

#import "PLEditTableViewController.h"

@interface PLEditTableViewController ()

@end

@implementation PLEditTableViewController

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
    
    
    self.navigationController.navigationBar.topItem.title = @"";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"edit-white-48"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editSuccessful:) name:@"BookmarkEditedSuccessfully" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkErrorReceived:) name:@"NetworkOperationFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkErrorReceived:) name:@"NetworkOperationTooSoon" object:nil];

    _descLabel.text = [_bookmarkToEdit desc];
    _descLabel.font = [UIFont fontWithName:@"Bree Serif" size:20];
    _urlLabel.text = [_bookmarkToEdit url];
    _tagView.text = [_bookmarkToEdit tag];
    _extendedView.text = [_bookmarkToEdit extended];
    
    _descLabel.tintColor = [UIColor pinlineBlue];
    _tagView.tintColor = [UIColor pinlineBlue];
    
    if ([_bookmarkToEdit.shared isEqualToString:@"yes"])
    {
        _sharedSwitch.on = YES;
    } else {
        _sharedSwitch.on = NO;
    }
    
    if ([_bookmarkToEdit.toread isEqualToString:@"yes"])
    {
        _toReadSwitch.on = YES;
    } else {
        _toReadSwitch.on = NO;
    }
    
    //[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"keyboard-down.png"] style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard:)];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    changesMade = FALSE;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (changesMade)
    {
        [self saveButtonPressed:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    changesMade = TRUE;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{

}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(IBAction)dismissKeyboard:(id)sender
{
    [_extendedView resignFirstResponder];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
}

-(IBAction)saveButtonPressed:(id)sender
{
    _bookmarkToEdit.desc  = _descLabel.text;
    _bookmarkToEdit.tag = _tagView.text;
    _bookmarkToEdit.extended = _extendedView.text;
    
    if (_toReadSwitch.on)
    {
        _bookmarkToEdit.toread = @"yes";
    } else {
        _bookmarkToEdit.toread = @"no";
    }
    if (_sharedSwitch.on)
    {
        _bookmarkToEdit.shared = @"yes";
    } else {
        _bookmarkToEdit.shared = @"no";
    }
    
    
    
    [[Pincore sharedManager] editBookmark:_bookmarkToEdit];
}

-(void)editSuccessful:(NSNotification *)note
{
    [TSMessage showNotificationInViewController:self.navigationController
                                          title:@"Saved"
                                       subtitle:@"Bookmark Saved"
                                          image:nil
                                           type:TSMessageNotificationTypeSuccess
                                       duration:1
                                       callback:nil
                                    buttonTitle:nil
                                 buttonCallback:nil
                                     atPosition:TSMessageNotificationPositionTop
                            canBeDismisedByUser:YES];
}

-(void)networkErrorReceived:(NSNotification *)note
{
    [TSMessage showNotificationWithTitle:[NSString stringWithFormat:@"Network Error"]
                                subtitle:[NSString stringWithFormat:@"Unable to connect to Pinboard."]
                                    type:TSMessageNotificationTypeError];
}

-(IBAction)changeMade:(id)sender
{
    changesMade = TRUE;
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    changesMade = TRUE;
    
    UIBarButtonItem *keyboardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"keyboard-down"] style:UIBarButtonItemStyleBordered target:self action:@selector(dismissKeyboard:)];
    [self.navigationItem setRightBarButtonItem:keyboardButton animated:YES];
}

@end
