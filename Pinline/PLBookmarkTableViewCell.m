//
//  PLBookmarkTableViewCell.m
//  Pinline
//
//  Created by Richard Allen on 11/12/13.
//

#import "PLBookmarkTableViewCell.h"

@implementation PLBookmarkTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(NSString *)accessibilityLabel
{
    return [NSString stringWithFormat:@"%@, %@", _descLabel.text, _urlLabel.text];
}

-(NSString *)accessibilityHint
{
    return @"Double tap to open this bookmark in a web browser. Swipe left for more options.";
}

@end
