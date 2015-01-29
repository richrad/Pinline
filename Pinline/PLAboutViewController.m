//
//  PLAboutViewController.m
//  Pinline
//
//  Created by Richard Allen on 12/8/13.
//

#import "PLAboutViewController.h"

@interface PLAboutViewController ()

@end

@implementation PLAboutViewController

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
    self.navigationController.navigationBar.topItem.title = @"";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"heart-white"]];
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [_webView loadHTMLString:htmlString baseURL:nil];

    _titleLabel.font = [UIFont fontWithName:@"Bree Serif" size:36.0];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)openTwitter:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/lapdogapps"]];
}

@end
