//
//  PLFeedTableViewController.h
//  Pinline
//
//  Created by Richard Allen on 12/22/13.
//

#import <UIKit/UIKit.h>
#import <MWFeedParser/MWFeedParser.h>

@interface PLFeedTableViewController : UITableViewController <MWFeedParserDelegate>
{
    MWFeedParser *feedParser;
    NSMutableArray *parsedItems;
    NSArray *itemsToDisplay;
    NSDateFormatter *formatter;
}

@property (nonatomic, weak) NSString *feedURLString;

-(void)updateTableWithParsedItems;

@end
