//
//  PLAddBookmarkTableViewController.m
//  Pinline
//
//  Created by Richard Allen on 12/15/13.
//

#import "PLAddBookmarkTableViewController.h"

@interface PLAddBookmarkTableViewController ()

@end

@implementation PLAddBookmarkTableViewController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editSuccessful:) name:@"BookmarkAddedSuccessfully" object:nil];
    
    webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    webview.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSEntityDescription *bookmarkEntity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:[[Pincore sharedManager] context]];
    _bookmark = [[Bookmark alloc] initWithEntity:bookmarkEntity insertIntoManagedObjectContext:nil];
    
    changesMade = NO;
    saved = NO;
    
    NSString *pasteboardString = [[UIPasteboard generalPasteboard] string];
    if ([pasteboardString hasPrefix:@"http://"] || [pasteboardString hasPrefix:@"https://"])
    {
        _urlLabel.text = pasteboardString;
        [self getPageTitleFromURLString:pasteboardString];
        changesMade = YES;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (!saved)
    {
        _bookmark = nil;
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
    if([_descLabel.text isEqualToString:@""])
    {
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Must Have Title"
                                           subtitle:@"Bookmarks must have a valid title."
                                              image:nil
                                               type:TSMessageNotificationTypeError
                                           duration:3
                                           callback:nil
                                        buttonTitle:nil
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionTop
                                canBeDismisedByUser:YES];
    } else if (!([_urlLabel.text hasPrefix:@"http://"] || [_urlLabel.text hasPrefix:@"https://"]))
    {
        [TSMessage showNotificationInViewController:self.navigationController
                                              title:@"Must Have Valid URL"
                                           subtitle:@"Bookmarks must have a valid URL."
                                              image:nil
                                               type:TSMessageNotificationTypeError
                                           duration:3
                                           callback:nil
                                        buttonTitle:nil
                                     buttonCallback:nil
                                         atPosition:TSMessageNotificationPositionTop
                                canBeDismisedByUser:YES];
    } else
    {
        _bookmark.url = _urlLabel.text;
        _bookmark.desc  = _descLabel.text;
        _bookmark.tag = _tagView.text;
        _bookmark.extended = _extendedView.text;
        _bookmark.dt = [NSDate date];
        
        if (_toReadSwitch.on)
        {
            _bookmark.toread = @"yes";
        } else {
            _bookmark.toread = @"no";
        }
        if (_sharedSwitch.on)
        {
            _bookmark.shared = @"yes";
        } else {
            _bookmark.shared = @"no";
        }
        
        [[Pincore sharedManager] addBookmark:_bookmark];
        [[[Pincore sharedManager] context] insertObject:_bookmark];
    }
}

-(void)editSuccessful:(NSNotification *)note
{
    saved = YES;
    [self performSegueWithIdentifier:@"doneEditingSegue" sender:self];
}

-(IBAction)cancelButtonPressed:(id)sender
{
    [self performSegueWithIdentifier:@"doneEditingSegue" sender:self];
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

-(void)getPageTitleFromURLString:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webview loadRequest:request];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    _descLabel.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

@end
