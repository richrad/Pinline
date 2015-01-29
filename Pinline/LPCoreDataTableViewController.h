//
//  LPCoreDataTableViewController.h
//  Lists
//
//  Created by Richard Allen on 12/26/13.
//Adapted from the book "Learning Core Data for iOS: A Hands-On Guide to Building Core Data Applications" by Tim Roadley
//

#import <UIKit/UIKit.h>
#import "Pincore.h"

@interface LPCoreDataTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;

-(void)performFetch;
-(NSFetchedResultsController *)fetchedResultsControllerFromTableView:(UITableView *)tableView;
-(UITableView *)tableViewFromFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

-(void)reloadSearchFetchedResultsControllerForPredicate:(NSPredicate *)predicate
                                             withEntity:(NSString *)entity
                                              inContext:(NSManagedObjectContext *)context
                                    withSortDescriptors:(NSArray *)sortDescriptors
                                 withSectionNameKeyPath:(NSString *)sectionNameKeyPath;

@end
