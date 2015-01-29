//
//  Tag.h
//  Pinline
//
//  Created by Richard Allen on 12/27/13.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Bookmark;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *bookmarks;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addBookmarksObject:(Bookmark *)value;
- (void)removeBookmarksObject:(Bookmark *)value;
- (void)addBookmarks:(NSSet *)values;
- (void)removeBookmarks:(NSSet *)values;

@end
