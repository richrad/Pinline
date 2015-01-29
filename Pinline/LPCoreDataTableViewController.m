//
//  LPCoreDataTableViewController.m
//  Lists
//
//  Created by Richard Allen on 12/26/13.
//  Adapted from the book "Learning Core Data for iOS: A Hands-On Guide to Building Core Data Applications" by Tim Roadley
//

#import "LPCoreDataTableViewController.h"

@interface LPCoreDataTableViewController ()

@end

@implementation LPCoreDataTableViewController

#pragma mark - GENERAL
-(NSFetchedResultsController *)fetchedResultsControllerFromTableView:(UITableView *)tableView
{
    return (tableView == self.tableView) ? self.fetchedResultsController : self.searchFetchedResultsController;
}

-(UITableView *)tableViewFromFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
{
    return (fetchedResultsController == self.fetchedResultsController) ? self.tableView : self.searchDisplayController.searchResultsTableView;
}

#pragma mark - FETCHING
-(void)performFetch
{
    if(_fetchedResultsController)
    {
        [[_fetchedResultsController managedObjectContext] performBlockAndWait:^{
            NSError *error = nil;
            if(![_fetchedResultsController performFetch:&error])
            {
                NSLog(@"Failed to perform fetch.");
            }
            [self.tableView reloadData];
        }];
    } else {
        NSLog(@"Failed to fetch, frc is nil");
    }
}

#pragma mark - DATASOURCE : UITableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[[self fetchedResultsControllerFromTableView:tableView] sections] objectAtIndex:section] numberOfObjects];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#pragma mark - DELEGATE : NSFetchedResultsController
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableViewFromFetchedResultsController:controller] beginUpdates];
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [[self tableViewFromFetchedResultsController:controller] endUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [[self tableViewFromFetchedResultsController:controller] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [[self tableViewFromFetchedResultsController:controller] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [[self tableViewFromFetchedResultsController:controller] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [[self tableViewFromFetchedResultsController:controller] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            if(!newIndexPath)
            {
                [[self tableViewFromFetchedResultsController:controller] reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [[self tableViewFromFetchedResultsController:controller] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                [[self tableViewFromFetchedResultsController:controller] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            break;
        case NSFetchedResultsChangeMove:
            [[self tableViewFromFetchedResultsController:controller] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [[self tableViewFromFetchedResultsController:controller] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

#pragma mark - DELEGATE : UISearchDisplayController
-(void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.searchFetchedResultsController.delegate = nil;
    self.searchFetchedResultsController = nil;
}

#pragma mark - SEARCH
-(void)reloadSearchFetchedResultsControllerForPredicate:(NSPredicate *)predicate
                                             withEntity:(NSString *)entity
                                              inContext:(NSManagedObjectContext *)context
                                    withSortDescriptors:(NSArray *)sortDescriptors
                                 withSectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity];
    [request setSortDescriptors:sortDescriptors];
    [request setPredicate:predicate];
    [request setFetchBatchSize:15];
    self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                              managedObjectContext:context
                                                                                sectionNameKeyPath:sectionNameKeyPath
                                                                                         cacheName:nil];
    self.searchFetchedResultsController.delegate = self;
    
    [self.searchFetchedResultsController.managedObjectContext performBlockAndWait:^{
        NSError *error;
        if(![self.searchFetchedResultsController performFetch:&error])
        {
            NSLog(@"Search fetch error: %@", error);
        }
    }];
}

-(void)configureSearch
{
    
}

@end
