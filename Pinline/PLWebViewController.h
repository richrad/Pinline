//
//  PLWebViewController.h
//  Pinline
//
//  Created by Richard Allen on 11/14/13.
//

#import <UIKit/UIKit.h>

typedef enum {
    WebViewContentTypeWeb,
    WebViewContentTypeReadability
} WebViewContentType;

@interface PLWebViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate>
{
    BOOL isFullScreen;
    UIActivityViewController *activityViewController;
    UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic) WebViewContentType webViewContentType;

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *activityButton;

@property (weak, nonatomic) NSString *receivedURLString;

@property (retain, nonatomic) UIToolbar *blurView;
@property (retain, nonatomic) UIButton *safariButton;
@property (retain, nonatomic) UIButton *cancelButton;

-(IBAction)activityButtonPressed:(id)sender;
-(IBAction)safariButtonPressed:(id)sender;
-(IBAction)cancelButtonPressed:(id)sender;

-(IBAction)safariButtonTouchDown:(id)sender;
-(IBAction)safariButtonTouchUpOutside:(id)sender;

-(IBAction)cancelButtonTouchDown:(id)sender;
-(IBAction)cancelButtonTouchUpOutside:(id)sender;

-(void)setWebviewControls;

@end
