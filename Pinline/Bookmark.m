//
//  Bookmark.m
//  Pinline
//
//  Created by Richard Allen on 11/26/13.
//

#import "Bookmark.h"
#import "Tag.h"


@implementation Bookmark

@dynamic desc;
@dynamic extended;
@dynamic shared;
@dynamic tag;
@dynamic dt;
@dynamic toread;
@dynamic url;
@dynamic tags;


- (void)prepareForDeletion
{
    NSMutableArray *tagsToDelete = [[NSMutableArray alloc] init];
    
    for (Tag *tag in self.tags)
    {
        if (tag.bookmarks.count == 1)
        {
            [tagsToDelete addObject:tag];
        }
    }
    
    for (Tag *tag in tagsToDelete)
    {
        [self.managedObjectContext deleteObject:tag];
    }
    
}

@end
