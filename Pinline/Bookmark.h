//
//  Bookmark.h
//  Pinline
//
//  Created by Richard Allen on 11/26/13.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Tag;

@interface Bookmark : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * extended;
@property (nonatomic, retain) NSString * shared;
@property (nonatomic, retain) NSString * tag;
@property (nonatomic, retain) NSDate * dt;
@property (nonatomic, retain) NSString * toread;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *tags;
@end

@interface Bookmark (CoreDataGeneratedAccessors)

- (void)addWithTagObject:(Tag *)value;
- (void)removeWithTagObject:(Tag *)value;
- (void)addWithTag:(NSSet *)values;
- (void)removeWithTag:(NSSet *)values;

@end
