//
//  PLDrawerView.h
//  Pinline
//
//  Created by Richard Allen on 11/16/13.
//

#import <UIKit/UIKit.h>
#import "PLBookmarkTableViewCell.h"

@interface PLDrawerView : UIView

@property (weak, nonatomic) IBOutlet UIButton *trashButton;
@property (weak, nonatomic) PLBookmarkTableViewCell *parentCell;
@property (weak, nonatomic) IBOutlet UIButton *bookButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *browserButton;



@end
