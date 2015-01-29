//
//  Pincore.h
//  Pinline
//
//  Created by Richard Allen on 12/3/13.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import <dispatch/dispatch.h>

typedef enum {
    TimerTypeAPI,
    TimerTypeAll
} TimerTypeToCheck;

@class Pincore;

@interface Pincore : NSObject
{
    BOOL getAllRunning;
    dispatch_queue_t backgroundQueue;
}

@property (nonatomic, readonly) NSManagedObjectContext          *context;
@property (nonatomic, readonly) NSManagedObjectContext          *backgroundContext;
@property (nonatomic, readonly) NSManagedObjectModel            *model;
@property (nonatomic, readonly) NSPersistentStoreCoordinator    *coordinator;
@property (nonatomic, readonly) NSPersistentStore               *store;

+(Pincore *)sharedManager;

-(NSString *)apiToken;

-(BOOL)checkTimer:(TimerTypeToCheck)timerType;

//Storage
-(NSString *)archivePath;
-(BOOL)saveContext;

-(Bookmark *)createBookmark;

-(void)deleteOrphanedTags;

//Network
-(void)authorizeUser:(NSString *)username withPassword:(NSString *)password;
-(void)getAllBookmarks;
-(void)checkForUpdates;
-(void)deleteBookmark:(Bookmark *)bookmarkToDelete;
-(void)editBookmark:(Bookmark *)bookmarkToEdit;
-(void)addBookmark:(Bookmark *)bookmarkToAdd;

-(BOOL)performBackgroundUpdate;

//End it All
-(void)logOut;

@end
