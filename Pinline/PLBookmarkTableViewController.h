//
//  PLBookmarkTableViewController.h
//  Pinline
//
//  Created by Richard Allen on 11/12/13.
//

#import <UIKit/UIKit.h>
#import "LPCoreDataTableViewController.h"
#import "HHPanningTableViewCell.h"

typedef enum {
    BookmarkArrayTypeAll,
    BookmarkArrayTypeToRead,
    BookmarkArrayTypeFromTag
} BookmarkArrayType;

@interface PLBookmarkTableViewController : LPCoreDataTableViewController <UISearchBarDelegate, UIGestureRecognizerDelegate, HHPanningTableViewCellDelegate, NSFetchedResultsControllerDelegate>
{
    UIActivityViewController *activityViewController;
}

@property (nonatomic) BookmarkArrayType bookmarkArrayType;
@property (nonatomic) Tag *tag;

-(IBAction)refresh:(id)sender;
-(IBAction)trashButtonPressed:(id)sender;
-(IBAction)bookButtonPressed:(id)sender;
-(IBAction)editButtonPressed:(id)sender;
-(IBAction)browserButtonPressed:(id)sender;
-(IBAction)shareButtonPressed:(id)sender;

-(void)updateTableCells:(NSNotification *)note;
-(void)networkErrorReceived:(NSNotification *)note;
-(void)networkTooSoonReceived:(NSNotification *)note;
-(void)noChangesNeeded:(NSNotification *)note;

@end
