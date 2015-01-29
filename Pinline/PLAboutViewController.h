//
//  PLAboutViewController.h
//  Pinline
//
//  Created by Richard Allen on 12/8/13.
//

#import <UIKit/UIKit.h>

@interface PLAboutViewController : UIViewController
{
    
}

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *byLabel;
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildLabel;

-(IBAction)openTwitter:(id)sender;

@end
