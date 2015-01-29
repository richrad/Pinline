//
//  PLBookmarkTableViewController.m
//  Pinline
//
//  Created by Richard Allen on 11/12/13.
//

#import "PLBookmarkTableViewController.h"
#import "PLBookmarkTableViewCell.h"
#import "Bookmark.h"
#import "PLWebViewController.h"
#import "PLDrawerView.h"
#import "PLEditTableViewController.h"
#import "TSMessage.h"
#import "ARSafariActivity.h"

@interface PLBookmarkTableViewController ()

@end

@implementation PLBookmarkTableViewController

-(void)configureFetch
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Bookmark"];
    [request setFetchBatchSize:50];
    
    switch (_bookmarkArrayType)
    {
        case BookmarkArrayTypeAll:
            break;
            
        case BookmarkArrayTypeToRead:
            [request setPredicate:[NSPredicate predicateWithFormat:@"toread == %@", @"yes"]];
            break;
            
        case BookmarkArrayTypeFromTag:
            [request setPredicate:[NSPredicate predicateWithFormat:@"ANY tags.name =[cd] %@", _tag.name]];
            //[request setPredicate:[NSPredicate predicateWithFormat:@"tags.name CONTAINS[cd] %@", _tag.name]];
            break;
    }
    
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dt" ascending:NO]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[Pincore sharedManager] context] sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController.delegate = self;
    //NSLog(@"predicate from config: %@", request.predicate);
}

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performFetch) name:@"SomethingChanged" object:nil];
    
    switch (_bookmarkArrayType)
    {
        case BookmarkArrayTypeAll:
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bookmark-white"]];
            break;
            
        case BookmarkArrayTypeToRead:
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newspaper-white"]];
            break;
        case BookmarkArrayTypeFromTag:
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bookmark-white"]];
            break;
    }
    
    self.navigationController.navigationBar.topItem.title = @"";
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@""
                                      style:UIBarButtonItemStyleBordered
                                     target:nil
                                     action:nil];
    
    self.tableView.backgroundView = nil;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    refreshControl.backgroundColor = [UIColor whiteColor];
    refreshControl.tintColor = [UIColor colorWithRed:0.600 green:0.757 blue:0.969 alpha:1.000];
    self.refreshControl = refreshControl;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableCells:) name:@"DoneProcessingBookmarks" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noChangesNeeded:) name:@"NoChangesNeeded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkErrorReceived:) name:@"NetworkOperationFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkTooSoonReceived:) name:@"NetworkOperationTooSoon" object:nil];
    
    [self configureFetch];
    [self performFetch];
    //[self.tableView reloadData];
    //[self.searchDisplayController.searchResultsTableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for(PLBookmarkTableViewCell *cell in [[self tableView] visibleCells])
    {
        [cell setDrawerRevealed:NO animated:YES];
    }
    for(PLBookmarkTableViewCell *cell in [[[self searchDisplayController] searchResultsTableView] visibleCells])
    {
        [cell setDrawerRevealed:NO animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PLBookmarkTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if(cell == nil)
    {
        cell = [[PLBookmarkTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.delegate = self;
    
    if(tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell.bookmark = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    } else {
        cell.bookmark = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    
    if(tableView == self.searchDisplayController.searchResultsTableView)
    {
        cell.bookmark = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    }
    
    //Set up the drawer views
    PLDrawerView *leftDrawerView = [[[NSBundle mainBundle] loadNibNamed:@"PLDrawerView" owner:self options:nil] lastObject];
    //PLMarkReadDrawerView *rightDrawerView = [[[NSBundle mainBundle] loadNibNamed:@"PLMarkReadDrawerView" owner:self options:nil] lastObject];
    
    leftDrawerView.parentCell = cell;
    
    [[leftDrawerView trashButton] addTarget:self action:@selector(trashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [[leftDrawerView bookButton] addTarget:self action:@selector(bookButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [[leftDrawerView editButton] addTarget:self action:@selector(editButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [[leftDrawerView shareButton] addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [[leftDrawerView browserButton] addTarget:self action:@selector(browserButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [[leftDrawerView trashButton] setAccessibilityLabel:@"Trash"];
    [[leftDrawerView trashButton] setAccessibilityHint:@"Double tap to delete this bookmark."];
    
    [[leftDrawerView browserButton] setAccessibilityLabel:@"Browser"];
    [[leftDrawerView browserButton] setAccessibilityHint:@"Double tap to open this bookmark in Safari."];
    
    [[leftDrawerView bookButton] setAccessibilityLabel:@"Reader"];
    [[leftDrawerView bookButton] setAccessibilityHint:@"Double tap to open this bookmark in reader view."];
    
    [[leftDrawerView shareButton] setAccessibilityLabel:@"Share"];
    [[leftDrawerView shareButton] setAccessibilityHint:@"Double tap to share this bookmark."];
    
    [[leftDrawerView editButton] setAccessibilityLabel:@"Edit"];
    [[leftDrawerView editButton] setAccessibilityHint:@"Double tap to edit this bookmark."];
    
    cell.drawerView = leftDrawerView;
    
    cell.directionMask = HHPanningTableViewCellDirectionLeft;
    
    // Configure the cell...
    [cell.descLabel setFont:[UIFont fontWithName:@"Bree Serif" size:20]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MM/dd/yy hh:mma"];
    
    NSString *dateString = [dateFormatter stringFromDate:[cell.bookmark dt]];
    
    [cell descLabel].text = [cell.bookmark desc];
    
    cell.timeLabel.numberOfLines = 2;
    cell.timeLabel.text = dateString;
    
    NSURL *url = [NSURL URLWithString:cell.bookmark.url];
    cell.urlLabel.text = [NSString stringWithFormat:@"%@", [url host]];
    
    if([[cell tagView] subviews])
    {
        for (UIView *view in [[cell tagView] subviews])
        {
            [view removeFromSuperview];
        }
    }
    
    NSArray *tagArray = [cell.bookmark.tag componentsSeparatedByString:@" "];
    
    if([[tagArray objectAtIndex:0] isEqualToString:@""])
    {
        
    } else
    {
        
        for (NSString *tag in tagArray)
        {
            UILabel *tagLabel = [[UILabel alloc] init];
            tagLabel.textColor = [UIColor whiteColor];
            tagLabel.text = tag;
            tagLabel.textAlignment = NSTextAlignmentCenter;
            
            tagLabel.isAccessibilityElement = YES;
            tagLabel.accessibilityLabel = [NSString stringWithFormat:@"Tag: %@", tag];
            
            [tagLabel sizeToFit];
            [tagLabel setFrame:CGRectMake(tagLabel.frame.origin.x, tagLabel.frame.origin.y, tagLabel.frame.size.width + 10, tagLabel.frame.size.height + 5)];
            tagLabel.backgroundColor = [UIColor pinlineBlue];
            tagLabel.layer.cornerRadius = 8;
            
            if ([[cell tagView] subviews])
            {
                UILabel *lastLabel = [[[cell tagView] subviews] lastObject];
            
                CGFloat newX = lastLabel.frame.origin.x + lastLabel.frame.size.width + 5;
                
                [tagLabel setFrame:CGRectMake(newX, tagLabel.frame.origin.y, tagLabel.frame.size.width, tagLabel.frame.size.height)];
            }
            
            if ([[[tagLabel text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
            {
                
            } else
            {
                [cell.tagView addSubview:tagLabel];
            }
            
        }
    }
    
    return cell;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    UITableView *tableView = controller.searchResultsTableView;
    tableView.rowHeight = [self.tableView rowHeight];
}

-(IBAction)browserButtonPressed:(id)sender
{
    PLDrawerView *drawerView = (PLDrawerView *)[sender superview];
    Bookmark *bookmark = drawerView.parentCell.bookmark;
    
    [drawerView.parentCell setDrawerRevealed:NO animated:YES];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:bookmark.url]];
    
}

-(IBAction)shareButtonPressed:(id)sender
{
    PLDrawerView *drawerView = (PLDrawerView *)[sender superview];
    Bookmark *bookmark = drawerView.parentCell.bookmark;
    
    NSURL *url = [NSURL URLWithString:bookmark.url];
    ARSafariActivity *safariActivity = [[ARSafariActivity alloc] init];
    
    
    activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[bookmark.desc, url] applicationActivities:@[safariActivity]];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

-(IBAction)trashButtonPressed:(id)sender
{
    PLDrawerView *drawerView = (PLDrawerView *)[sender superview];
    Bookmark *bookmark = drawerView.parentCell.bookmark;
    [drawerView.parentCell setDrawerRevealed:NO animated:YES];
    
    [[Pincore sharedManager] deleteBookmark:bookmark];
}


-(IBAction)bookButtonPressed:(id)sender
{
    PLDrawerView *drawerView = (PLDrawerView *)[sender superview];
    NSString *urlString = drawerView.parentCell.bookmark.url;
    
    [self performSegueWithIdentifier:@"pushToReadViewSegue" sender:urlString];
}

-(IBAction)editButtonPressed:(id)sender
{
    PLDrawerView *drawerView = (PLDrawerView *)[sender superview];
    Bookmark *bookmarkToEdit = drawerView.parentCell.bookmark;
    
    [self performSegueWithIdentifier:@"pushToEdit" sender:bookmarkToEdit];
}


- (IBAction)refresh:(id)sender
{
    [[Pincore sharedManager] checkForUpdates];
}

-(void)updateTableCells:(NSNotification *)note
{
    if([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
    }
    
    //[[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    //[[self tableView] reloadData];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor pinlineBlue];
    bgColorView.layer.masksToBounds = YES;
    [cell setSelectedBackgroundView:bgColorView];
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    PLBookmarkTableViewCell *theCell = (PLBookmarkTableViewCell *)cell;
    [theCell setDrawerRevealed:NO animated:NO];
}

#pragma mark -- Segue methods

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if([identifier isEqualToString:@"pushToWebViewSegue"])
    {
        PLBookmarkTableViewCell *selectedCell = sender;
        if([selectedCell isDrawerRevealed])
        {
            return NO;
        } else
        {
            return YES;
        }
    } else if ([identifier isEqualToString:@"pushToReadViewSegue"])
    {
        return YES;
    }
    return YES;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"pushToWebViewSegue"])
    {
        PLBookmarkTableViewCell *selectedCell = sender;
        
        NSString *urlString = selectedCell.bookmark.url;
        
        [[segue destinationViewController] setWebViewContentType:WebViewContentTypeWeb];
        [[segue destinationViewController] setReceivedURLString:urlString];
    }
    if([[segue identifier] isEqualToString:@"pushToEdit"])
    {
        [[segue destinationViewController] setBookmarkToEdit:sender];
    }
    if([[segue identifier] isEqualToString:@"pushToReadViewSegue"])
    {
        [[segue destinationViewController] setWebViewContentType:WebViewContentTypeReadability];
        [[segue destinationViewController] setReceivedURLString:sender];
    }
}


#pragma mark -- Search Controller Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if (searchString.length > 0)
    {
        if (_bookmarkArrayType == BookmarkArrayTypeFromTag)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.tag contains[c] %@ AND (SELF.desc contains[c] %@ OR SELF.tag contains[c] %@)", _tag.name, searchString, searchString];
            NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"dt" ascending:NO], nil];
            
            [self reloadSearchFetchedResultsControllerForPredicate:predicate
                                                        withEntity:@"Bookmark"
                                                         inContext:[[Pincore sharedManager] context]
                                               withSortDescriptors:sortDescriptors
                                            withSectionNameKeyPath:nil];
        } else if (_bookmarkArrayType == BookmarkArrayTypeAll) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.desc contains[c] %@ OR SELF.tag contains[c] %@", searchString, searchString];
            NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"dt" ascending:NO], nil];
            
            [self reloadSearchFetchedResultsControllerForPredicate:predicate
                                                        withEntity:@"Bookmark"
                                                         inContext:[[Pincore sharedManager] context]
                                               withSortDescriptors:sortDescriptors
                                            withSectionNameKeyPath:nil];
        } else if (_bookmarkArrayType == BookmarkArrayTypeToRead)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.toread contains[c] %@ AND (SELF.desc contains[c] %@ OR SELF.tag contains[c] %@)", @"yes", searchString, searchString];
            NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"dt" ascending:NO], nil];
            
            [self reloadSearchFetchedResultsControllerForPredicate:predicate
                                                        withEntity:@"Bookmark"
                                                         inContext:[[Pincore sharedManager] context]
                                               withSortDescriptors:sortDescriptors
                                            withSectionNameKeyPath:nil];

        }
        
    } else {
        return NO;
    }
    return YES;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.tintColor = [UIColor pinlineBlue];
    
    for(PLBookmarkTableViewCell *cell in [[self tableView] visibleCells])
    {
        [cell setDrawerRevealed:NO animated:YES];
    }
}

#pragma mark - Alert Methods

-(void)networkErrorReceived:(NSNotification *)note
{
    if([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
    }
}

-(void)networkTooSoonReceived:(NSNotification *)note
{
    if([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
    }
}

-(void)noChangesNeeded:(NSNotification *)note
{
    if([self.refreshControl isRefreshing])
    {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark -- Tag List Delegate

-(void)selectedTag:(NSString *)tagName
{
    NSLog(@"%@", tagName);
}

@end
