//
//  PLFeedTableViewCell.h
//  Pinline
//
//  Created by Richard Allen on 12/22/13.
//

#import <UIKit/UIKit.h>

@interface PLFeedTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextView *summaryView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic) BOOL isSaved;

@end
