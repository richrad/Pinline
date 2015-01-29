//
//  PLBookmarkTableViewCell.h
//  Pinline
//
//  Created by Richard Allen on 11/12/13.
//

#import <UIKit/UIKit.h>
#import "HHPanningTableViewCell.h"
#import "Bookmark.h"


@interface PLBookmarkTableViewCell : HHPanningTableViewCell
{
    
}

@property (strong, nonatomic) Bookmark *bookmark;
@property (weak, nonatomic) IBOutlet UITextView *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UIView *tagView;

@end
