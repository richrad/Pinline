//
//  PLWebViewController.m
//  Pinline
//
//  Created by Richard Allen on 11/14/13.
//

#import "PLWebViewController.h"
#import "ARSafariActivity.h"

@interface PLWebViewController ()

@end

@implementation PLWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    isFullScreen = NO;
    
    [_toolbar setFrame:CGRectMake(_toolbar.frame.origin.x, _toolbar.frame.origin.y, _toolbar.frame.size.width, 22)];
    
    self.webView.scrollView.delegate = self;
    
    if(_webViewContentType == WebViewContentTypeWeb)
    {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"browser-white"]];
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:_receivedURLString]]];
    } else if(_webViewContentType == WebViewContentTypeReadability)
    {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newspaper-white"]];
        NSString *readabilityURLString = [NSString stringWithFormat:@"http://mobilizer.instapaper.com/m?u=%@", _receivedURLString];
        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:readabilityURLString]]];
    }
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
    _backButton.enabled = NO;
    _forwardButton.enabled = NO;
    _activityButton.enabled = NO;
        
    _backButton.accessibilityLabel = @"Go back.";
    _backButton.accessibilityHint = @"Double tap to go back in the web browser.";
    _forwardButton.accessibilityLabel = @"Go forward";
    _forwardButton.accessibilityHint = @"Double tap to go forward in the web browser.";
    _activityButton.accessibilityLabel = @"Share";
    _activityButton.accessibilityHint = @"Double tap to share this web page.";
}


-(void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)activityButtonPressed:(id)sender
{
    ARSafariActivity *safariActivity = [[ARSafariActivity alloc] init];
    
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[_webView.request.URL] applicationActivities:@[safariActivity]];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

-(IBAction)cancelButtonPressed:(id)sender
{
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:1 options:0 animations:^{
        [_blurView setAlpha:0];
        _safariButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
        _cancelButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
    } completion:^(BOOL finished)
     {
         [_blurView removeFromSuperview];
     }];
}

-(IBAction)safariButtonPressed:(id)sender
{
    [_safariButton setBackgroundColor:[UIColor whiteColor]];
    [_safariButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:1 options:0 animations:^{
        [_blurView setAlpha:0];
        _safariButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
        _cancelButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
    } completion:^(BOOL finished)
     {
         [_blurView removeFromSuperview];
         [[UIApplication sharedApplication] openURL:_webView.request.URL];
     }];
}

-(IBAction)safariButtonTouchDown:(id)sender
{
    [_safariButton setBackgroundColor:[UIColor pinlineBlue]];
    [_safariButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
}

-(IBAction)safariButtonTouchUpOutside:(id)sender
{
    [_safariButton setBackgroundColor:[UIColor whiteColor]];
    [_safariButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

-(IBAction)cancelButtonTouchDown:(id)sender
{
    [_cancelButton setBackgroundColor:[UIColor redColor]];
    [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
}

-(IBAction)cancelButtonTouchUpOutside:(id)sender
{
    [_cancelButton setBackgroundColor:[UIColor blackColor]];
    [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void)setWebviewControls
{
    if(_webView.canGoBack)
    {
        _backButton.enabled = YES;
    } else if (!_webView.canGoBack)
    {
        _backButton.enabled = NO;
    }
    if(_webView.canGoForward)
    {
        _forwardButton.enabled = YES;
    } else if (!_webView.canGoForward)
    {
        _forwardButton.enabled = NO;
    }
}

#pragma mark -- Web View Delegate

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [self setWebviewControls];
    [activityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self setWebviewControls];
    [activityIndicator stopAnimating];
    _activityButton.enabled = YES;
}

@end
