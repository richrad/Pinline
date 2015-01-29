//
//  PLMainMenuTableViewController.m
//  Pinline
//
//  Created by Richard Allen on 11/17/13.
//

#import "PLMainMenuTableViewController.h"
#import "PLBookmarkTableViewController.h"
#import "TSMessage.h"
#import "PLFeedTableViewController.h"

@interface PLMainMenuTableViewController ()

@end

@implementation PLMainMenuTableViewController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noChangesNeeded:) name:@"NoChangesNeeded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noChangesNeeded:) name:@"NetworkOperationTooSoon" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountLabels:) name:@"DoneProcessingBookmarks" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkErrorReceived:) name:@"NetworkOperationFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logOutSuccessful:) name:@"LogOutSuccessful" object:nil];
    
    _addBookmarkButton.accessibilityLabel = @"Add Bookmark";
    _addBookmarkButton.accessibilityHint = @"Double tap to add a new bookmark.";
    
    self.navigationController.navigationBar.topItem.title = @"";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"thumbtack"]];
    
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,nil]];
    
    [TSMessage setDefaultViewController:self];

    
    _allBookmarksCountLabel.textColor = [UIColor whiteColor];
    _allBookmarksCountLabel.backgroundColor = [UIColor colorWithRed:0.533 green:0.690 blue:0.953 alpha:1.000];
    _allBookmarksCountLabel.layer.cornerRadius = 8;
    
    _toReadBookmarksCountLabel.textColor = [UIColor whiteColor];
    _toReadBookmarksCountLabel.backgroundColor = [UIColor colorWithRed:0.533 green:0.690 blue:0.953 alpha:1.000];
    _toReadBookmarksCountLabel.layer.cornerRadius = 8;
    
    _tagsCountLabel.textColor = [UIColor whiteColor];
    _tagsCountLabel.backgroundColor = [UIColor colorWithRed:0.533 green:0.690 blue:0.953 alpha:1.000];
    _tagsCountLabel.layer.cornerRadius = 8;
    
    [TSMessage setDefaultViewController:self.navigationController];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    refreshControl.backgroundColor = [UIColor whiteColor];
    refreshControl.tintColor = [UIColor colorWithRed:0.600 green:0.757 blue:0.969 alpha:1.000];
    self.refreshControl = refreshControl;
    
    self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
    [self.refreshControl beginRefreshing];
    [[Pincore sharedManager] checkForUpdates];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //deselect row if we're coming back from the detail view
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if(indexPath)
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    [self updateCountLabels:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"pushToAllBookmarks"])
    {
        [[segue destinationViewController] setBookmarkArrayType:BookmarkArrayTypeAll];
    }
    if([[segue identifier] isEqualToString:@"pushToToRead"])
    {
        [[segue destinationViewController] setBookmarkArrayType:BookmarkArrayTypeToRead];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell  *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if(selectedCell.tag == 999)
    {
        [selectedCell setSelected:NO animated:YES];
        [self confirmLogOut];
    }
}

-(void)updateCountLabels:(NSNotification *)note
{
    if(self.refreshControl.isEnabled)
    {
        [self.refreshControl endRefreshing];
    }
    
    NSError *error;
    NSFetchRequest *allCountRequest = [[NSFetchRequest alloc] init];
    [allCountRequest setEntity:[NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:[[Pincore sharedManager] context]]];
    
    long allCount = [[[Pincore sharedManager] context] countForFetchRequest:allCountRequest error:&error];
    
    NSFetchRequest *toReadCountRequest = [[NSFetchRequest alloc] init];
    [toReadCountRequest setEntity:[NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:[[Pincore sharedManager] context]]];
    [toReadCountRequest setPredicate:[NSPredicate predicateWithFormat:@"toread == %@", @"yes"]];
    
    long toReadCount = [[[Pincore sharedManager] context] countForFetchRequest:toReadCountRequest error:&error];
    
    NSFetchRequest *tagCountRequest = [[NSFetchRequest alloc] init];
    [tagCountRequest setEntity:[NSEntityDescription entityForName:@"Tag" inManagedObjectContext:[[Pincore sharedManager] context]]];
    
    long tagCount = [[[Pincore sharedManager] context] countForFetchRequest:tagCountRequest error:&error];
    
    _allBookmarksCountLabel.text = [NSString stringWithFormat:@"%li", allCount];
    _toReadBookmarksCountLabel.text = [NSString stringWithFormat:@"%li", toReadCount];
    _tagsCountLabel.text = [NSString stringWithFormat:@"%li", tagCount];
}

-(void)networkErrorReceived:(NSNotification *)note
{
    if([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
    }
    
    
    [TSMessage showNotificationWithTitle:[NSString stringWithFormat:@"Network Error"]
                                subtitle:[NSString stringWithFormat:@"Unable to connect to Pinboard."]
                                    type:TSMessageNotificationTypeError];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor pinlineBlue];
    bgColorView.layer.masksToBounds = YES;
    [cell setSelectedBackgroundView:bgColorView];
}

-(void)confirmLogOut
{
    _blurView = [[UIToolbar alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [_blurView setBarStyle:UIBarStyleBlackTranslucent];
    [_blurView setAlpha:0];
    
    _logOutButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x - 140, 700, 280, 60)];
    [_logOutButton setBackgroundColor:[UIColor whiteColor]];
    [[_logOutButton layer] setCornerRadius:8];
    [_logOutButton setTitle:@"Log Out" forState:UIControlStateNormal];
    [[_logOutButton titleLabel] setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
    [_logOutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_logOutButton addTarget:self action:@selector(logOutButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_logOutButton addTarget:self action:@selector(logOutButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_logOutButton addTarget:self action:@selector(logOutButtonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x - 140, 700, 280, 60)];
    [_cancelButton setBackgroundColor:[UIColor blackColor]];
    [[_cancelButton layer] setCornerRadius:8];
    [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [[_cancelButton titleLabel] setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
    [_cancelButton setTintColor:[UIColor whiteColor]];
    [_cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_cancelButton addTarget:self action:@selector(cancelButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_cancelButton addTarget:self action:@selector(cancelButtonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    
    [_blurView addSubview:_logOutButton];
    [_blurView addSubview:_cancelButton];
    
    [[[UIApplication sharedApplication] keyWindow] addSubview:_blurView];
    
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:1 options:0 animations:^{
        [_blurView setAlpha:1];
        [_logOutButton setFrame:CGRectMake(20, CGRectGetMaxY(self.view.frame) - 140, 280, 60)];
        [_cancelButton setFrame:CGRectMake(_logOutButton.frame.origin.x, _logOutButton.frame.origin.y + 70, 280, 60)];
    } completion:^(BOOL finished)
     {
         
     }];
}

-(void)logOut
{
    [[Pincore sharedManager] logOut];
}

-(IBAction)logOutButtonPressed:(id)sender
{
    [_logOutButton setBackgroundColor:[UIColor whiteColor]];
    [_logOutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:1 options:0 animations:^{
        [_blurView setAlpha:0];
        _logOutButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
        _cancelButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
    } completion:^(BOOL finished)
     {
         [_blurView removeFromSuperview];
         [self logOut];
     }];
}

-(IBAction)logOutButtonTouchDown:(id)sender
{
    [_logOutButton setBackgroundColor:[UIColor pinlineBlue]];
    [_logOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(IBAction)logOutButtonTouchUpOutside:(id)sender
{
    [_logOutButton setBackgroundColor:[UIColor whiteColor]];
    [_logOutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

-(IBAction)cancelButtonPressed:(id)sender
{
    [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:1 options:0 animations:^{
        [_blurView setAlpha:0];
        _logOutButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
        _cancelButton.frame = CGRectMake(self.view.center.x - 140, 700, 280, 100);
    } completion:^(BOOL finished)
     {
         [_blurView removeFromSuperview];
     }];
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

-(void)logOutSuccessful:(NSNotification *)note
{
    [self performSegueWithIdentifier:@"logOutSegue" sender:nil];
}

- (IBAction)refresh:(id)sender
{
    [[Pincore sharedManager] checkForUpdates];
}

-(void)noChangesNeeded:(NSNotification *)note
{
    if([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
