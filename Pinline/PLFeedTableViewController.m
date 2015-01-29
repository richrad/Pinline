//
//  PLFeedTableViewController.m
//  Pinline
//
//  Created by Richard Allen on 12/22/13.
//

#import "PLFeedTableViewController.h"
#import "PLFeedTableViewCell.h"

@interface PLFeedTableViewController ()

@end

@implementation PLFeedTableViewController

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
    
    self.navigationController.navigationBar.topItem.title = @"";
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lightbulb-white"]];
    
    self.tableView.scrollsToTop = YES;
    
    parsedItems = [[NSMutableArray alloc] init];
    itemsToDisplay = [[NSArray alloc] init];
    
    formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
    
    _feedURLString = @"http://feeds.pinboard.in/rss/popular/";
    
    NSURL *feedURL = [NSURL URLWithString:_feedURLString];
    
    feedParser = [[MWFeedParser alloc] initWithFeedURL:feedURL];
    feedParser.delegate = self;
    feedParser.feedParseType = ParseTypeFull;
    feedParser.connectionType = ConnectionTypeAsynchronously;
    
    [feedParser parse];
}

- (void)updateTableWithParsedItems
{
	itemsToDisplay = [parsedItems sortedArrayUsingDescriptors:
                                    [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date"
                                                                                ascending:NO]]];
	[self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark MWFeedParserDelegate

-(void)feedParserDidStart:(MWFeedParser *)parser
{
	NSLog(@"Started Parsing: %@", parser.url);
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
	NSLog(@"Parsed Feed Info: “%@”", info.title);
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
	NSLog(@"Parsed Feed Item: “%@”", item.title);
	if(item)
    {
        [parsedItems addObject:item];
    }
}

-(void)feedParserDidFinish:(MWFeedParser *)parser
{
	NSLog(@"Finished Parsing%@", (parser.stopped ? @" (Stopped)" : @""));
    [self updateTableWithParsedItems];
}

-(void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
	NSLog(@"Finished Parsing With Error: %@", error);
    if (parsedItems.count == 0) {
        self.title = @"Failed"; // Show failed message in title
    } else {
        // Failed but some items parsed, so show and inform of error
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Parsing Incomplete"
                                                        message:@"There was an error during the parsing of this feed. Not all of the feed items could parsed."
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    }
    [self updateTableWithParsedItems];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return itemsToDisplay.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    PLFeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil)
    {
        cell = [[PLFeedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    MWFeedItem *item = [itemsToDisplay objectAtIndex:indexPath.row];
	if (item)
    {
		cell.titleLabel.text = item.title;
        cell.summaryView.text = item.summary;
        cell.dateLabel.text = [NSString stringWithFormat:@"%@", [formatter stringFromDate:item.date]];
    
        [cell.titleLabel setFont:[UIFont fontWithName:@"Bree Serif" size:20]];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MWFeedItem *item = [itemsToDisplay objectAtIndex:indexPath.row];
    
    Bookmark *bookmark = [[Pincore sharedManager] createBookmark];
    bookmark.url = item.link;
    bookmark.desc = item.title;
    bookmark.extended = item.description;
    bookmark.tag = @"";
    bookmark.dt = [NSDate date];
    bookmark.toread = @"yes";
    bookmark.shared = @"no";
    
    [[Pincore sharedManager] addBookmark:bookmark];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end