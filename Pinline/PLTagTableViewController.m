//
//  PLTagTableViewController.m
//  Pinline
//
//  Created by Richard Allen on 12/27/13.
//

#import "PLTagTableViewController.h"
#import "PLBookmarkTableViewController.h"
#import "Tag.h"

@interface PLTagTableViewController ()

@end

@implementation PLTagTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tag-white"]];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.backgroundColor = [UIColor whiteColor];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget:self action:@selector(stopRefreshControl) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
    
    [self configureFetch];
    [self performFetch];
}

-(void)stopRefreshControl
{
    [self.refreshControl endRefreshing];
}

-(void)configureFetch
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    [request setFetchBatchSize:50];

    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[Pincore sharedManager] context] sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController.delegate = self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if(tableView == self.searchDisplayController.searchResultsTableView)
    {
        tag = [self.searchFetchedResultsController objectAtIndexPath:indexPath];
    }
    
    cell.textLabel.text = [tag name];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor pinlineBlue];
    bgColorView.layer.masksToBounds = YES;
    [cell setSelectedBackgroundView:bgColorView];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PLBookmarkTableViewController *destination = [segue destinationViewController];
    [destination setBookmarkArrayType:BookmarkArrayTypeFromTag];
    
    UITableView *tableView = (UITableView *)[[sender superview] superview];
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        [destination setTag:[self.searchFetchedResultsController objectAtIndexPath:[tableView indexPathForSelectedRow]]];
    } else {
        [destination setTag:[self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]]];
    }
    
}

#pragma mark -- Search Controller Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if (searchString.length > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[c] %@", searchString];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil];
        
        [self reloadSearchFetchedResultsControllerForPredicate:predicate
                                                    withEntity:@"Tag"
                                                     inContext:[[Pincore sharedManager] context]
                                           withSortDescriptors:sortDescriptors
                                        withSectionNameKeyPath:nil];
    } else {
        return NO;
    }
    return YES;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.tintColor = [UIColor pinlineBlue];
}

@end
