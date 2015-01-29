//
//  PLDoneEditingSegue.m
//  Pinline
//
//  Created by Richard Allen on 1/2/14.
//

#import "PLDoneEditingSegue.h"
#import "PLNavigationController.h"

@implementation PLDoneEditingSegue

-(void)perform
{
    UIViewController *source = [(UIViewController *)[self sourceViewController] navigationController];
    PLNavigationController *destination = [self destinationViewController];
    
    UIGraphicsBeginImageContextWithOptions(source.view.bounds.size, YES, 0.0f);
    [source.view drawViewHierarchyInRect:source.view.bounds afterScreenUpdates:YES];
    UIImage *screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *screenShotView = [[UIImageView alloc] initWithImage:screenshot];
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[screenShotView]];
    gravity.magnitude = 4.0;
    
    [destination.view addSubview:screenShotView];
    destination.animator = [[UIDynamicAnimator alloc] initWithReferenceView:destination.view];
    [destination.animator addBehavior:gravity];
    
    [source presentViewController:destination animated:NO completion:nil];
}

@end
