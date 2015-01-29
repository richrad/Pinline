//
//  Pincore.m
//  Pinline
//
//  Created by Richard Allen on 12/3/13.
//

#import "Pincore.h"
#import "QSDateParser.h"
#import "NSString+JustNumbers.h"
#import "JSONResponseSerializer.h"

@implementation Pincore

-(NSString *)apiToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"APIToken"];
}

-(NSDate *)lastAPIRequestDate
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"LastAPIRequestDate"])
    {
        NSDate *now = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:[now dateByAddingTimeInterval:(-3*2)] forKey:@"LastAPIRequestDate"];
    }
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"LastAPIRequestDate"];
}

-(NSDate *)lastGetAllBookmarksDate
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"LastGetAllBookmarksDate"])
    {
        NSDate *now = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:[now dateByAddingTimeInterval:(-60*6)] forKey:@"LastGetAllBookmarksDate"];
    }
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"LastGetAllBookmarksDate"];
}

-(NSDate *)lastLocalUpdate
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"LastLocalUpdate"])
    {
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Bookmark"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"dt" ascending:NO]];
        request.fetchBatchSize = 1;
        NSError *error;
        NSArray *bookmarksArray = [_context executeFetchRequest:request error:&error];
        
        if ([bookmarksArray count] == 0)
        {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate distantPast] forKey:@"LastLocalUpdate"];
        } else {
            Bookmark *lastBookmark = [bookmarksArray objectAtIndex:0];
            NSDate *lastLocalUpdate = [lastBookmark dt];
            
            [[NSUserDefaults standardUserDefaults] setObject:lastLocalUpdate forKey:@"LastLocalUpdate"];
        }
    }
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"LastLocalUpdate"];
}

-(id)init
{
    self = [super init];
    if(self)
    {
        getAllRunning = NO;
        
        //Storage
        _model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        NSString *path = [self archivePath];
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        
        NSError *error = nil;
        
        if (![_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeURL
                                     options:nil
                                       error:&error])
        {
            [NSException raise:@"Open failed"
                        format:@"Reason: %@", [error localizedDescription]];
        }
        
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_context setPersistentStoreCoordinator:_coordinator];
        [_context setUndoManager:nil];
        
        _backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_backgroundContext setParentContext:_context];
        
        [self deleteOrphanedTags];
        
        backgroundQueue = dispatch_queue_create("me.lapdog.pinline.bgq", NULL);
        
        return self;
    }
    return self;
}

+(Pincore *)sharedManager
{
    static Pincore *sharedManager = nil;
    if(!sharedManager)
    {
        sharedManager = [[super allocWithZone:nil] init];
    }
    return sharedManager;
}

+(id)allocWithZone:(NSZone *)zone
{
    return [self sharedManager];
}

-(BOOL)checkTimer:(TimerTypeToCheck)timerType;
{
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *componentsAPI = [calendar components:NSSecondCalendarUnit
                                                  fromDate:[self lastAPIRequestDate]
                                                    toDate:now
                                                   options:0];
    NSDateComponents *componentsAll = [calendar components:NSMinuteCalendarUnit
                                                  fromDate:[self lastGetAllBookmarksDate]
                                                    toDate:now
                                                   options:0];
    
    NSLog(@"Seconds since last API Request: %li", (long)componentsAPI.second);
    NSLog(@"Minutes since last All Request: %li", (long)componentsAll.minute);
    
    if(timerType == TimerTypeAPI)
    {
        if (componentsAPI.second < 3)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationTooSoon" object:nil];
            return NO;
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastAPIRequestDate"];
            return YES;
        }
    } else if (timerType == TimerTypeAll)
    {
        if (componentsAll.minute < 5)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationTooSoon" object:nil];
            return NO;
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastAPIRequestDate"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastGetAllBookmarksDate"];
            return YES;
        }
    }
    
    return NO;
}

#pragma mark -- Storage Ops

-(NSString *)archivePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    
    return [documentDirectory stringByAppendingPathComponent:@"store.data"];
}

-(BOOL)saveContext
{
    NSError *error = nil;
    BOOL successful = [_context save:&error];
    if(!successful)
    {
        NSLog(@"Error saving: %@", [error localizedDescription]);
    }
    
    return successful;
}

-(Bookmark *)createBookmark
{
    Bookmark *newBookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:_context];
    return newBookmark;
}


-(void)processBookmarks:(NSArray *)bookmarksArray
{
    
    
    
    [_backgroundContext performBlock:^(void){
        
        for (NSDictionary *bookmarkDict in bookmarksArray)
        {
            NSError *error;
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:[NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:_backgroundContext]];
            [fetchRequest setFetchLimit:1];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url == %@", [bookmarkDict objectForKey:@"href"]]];
            
            Bookmark *newBookmark;
            
            if ([_backgroundContext countForFetchRequest:fetchRequest error:&error])
            {
                newBookmark = [[_backgroundContext executeFetchRequest:fetchRequest error:&error] lastObject];
            } else
            {
                newBookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:_backgroundContext];
            }
            
            newBookmark.url = [bookmarkDict objectForKey:@"href"];
            newBookmark.dt = QSDateWithString([bookmarkDict objectForKey:@"time"]);
            newBookmark.desc = [bookmarkDict objectForKey:@"description"];
            newBookmark.extended = [bookmarkDict objectForKey:@"extended"];
            newBookmark.tag = [bookmarkDict objectForKey:@"tags"];
            newBookmark.shared = [bookmarkDict objectForKey:@"shared"];
            newBookmark.toread = [bookmarkDict objectForKey:@"toread"];
            
            NSArray *tagArray = [[newBookmark tag] componentsSeparatedByString:@" "];
            NSMutableSet *tagSet = [[NSMutableSet alloc] init];
            
            for (NSString *tag in tagArray)
            {
                if (![[tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                {
                    NSError *error;
                    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Tag" inManagedObjectContext:_backgroundContext]];
                    [fetchRequest setFetchLimit:1];
                    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", [tag lowercaseString]]];
                    
                    Tag *newTag;
                    
                    if ([_backgroundContext countForFetchRequest:fetchRequest error:&error])
                    {
                        newTag = [[_backgroundContext executeFetchRequest:fetchRequest error:&error] lastObject];
                    } else
                    {
                        newTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:_backgroundContext];
                    }
                    
                    newTag.name = [tag lowercaseString];
                    [tagSet addObject:newTag];
                }
                
                newBookmark.tags = [NSSet setWithSet:tagSet];
            }
         
            //This bookmark processed
            if (([bookmarksArray indexOfObject:bookmarkDict] % 100) == 0)
            {
                [_backgroundContext save:nil];
                dispatch_sync(dispatch_get_main_queue(), ^(void){
                    [self saveContext];
                });
                [self performSelectorOnMainThread:@selector(postProcessCompletionNotification) withObject:nil waitUntilDone:NO];
            }
        }
        
        //All bookmarks processed
        [_backgroundContext save:nil];
        dispatch_sync(dispatch_get_main_queue(), ^(void){
            [self saveContext];
        });
        [self performSelectorOnMainThread:@selector(postProcessCompletionNotification) withObject:nil waitUntilDone:NO];
    }];
    
}

-(void)postProcessCompletionNotification
{
    //NSLog(@"notification posted");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DoneProcessingBookmarks" object:nil];
}

#pragma mark -- Network Ops

-(void)authorizeUser:(NSString *)username withPassword:(NSString *)password
{
    NSLog(@"authorize user");
    
    NSString *encodedPasswordString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                            NULL,
                                                                                                            (CFStringRef)password,
                                                                                                            NULL,
                                                                                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                            kCFStringEncodingUTF8 ));
    
    NSString *getString = [NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/user/api_token&format=json", username, encodedPasswordString];
    NSLog(@"%@", getString);
    NSURL *url = [NSURL URLWithString:getString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[JSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments]];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSLog(@"Response Code: %ld", (long)operation.response.statusCode);
         
         NSString *formattedToken = [NSString stringWithFormat:@"%@:%@", username, [responseObject objectForKey:@"result"]];
         
         [[NSUserDefaults standardUserDefaults] setObject:formattedToken forKey:@"APIToken"];
         [[NSNotificationCenter defaultCenter] postNotificationName:@"AuthApprovedNotification" object:nil];
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *statusCode = [[operation responseString] justNumbers];
         NSLog(@"status code: %@", statusCode);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"AuthFailedNotification" object:nil];
     }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

-(void)getAllBookmarks
{
    NSLog(@"get all bookmarks");
    
    if (![self checkTimer:TimerTypeAll])
    {
        [self getRecentBookmarks];
        return;
    }
    
    NSString *getString = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/all?format=json&auth_token=%@", [self apiToken]];
    NSLog(@"%@", getString);
    NSURL *url = [NSURL URLWithString:getString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[JSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         getAllRunning = NO;
         NSLog(@"Response Code: %ld", (long)operation.response.statusCode);
         
         NSArray *bookmarksArray = responseObject;
         
         dispatch_async(backgroundQueue, ^(void){
             [self processBookmarks:bookmarksArray];
         });
         
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         getAllRunning = NO;
         NSString *statusCode = [[operation responseString] justNumbers];
         NSLog(@"status code: %@", statusCode);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationFailed" object:nil];
     }];
    
    if(getAllRunning == NO)
    {
        getAllRunning = YES;
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
    
}

-(void)getRecentBookmarks
{
    if (![self checkTimer:TimerTypeAPI])
    {
        return;
    }
    
    NSString *getString = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/recent?format=json&auth_token=%@&count=100", [self apiToken]];
    NSLog(@"%@", getString);
    NSURL *url = [NSURL URLWithString:getString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[JSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSLog(@"Response Code: %ld", (long)operation.response.statusCode);
         
         NSArray *bookmarksArray = [responseObject objectForKey:@"posts"];
        
         dispatch_async(backgroundQueue, ^(void){
             [self processBookmarks:bookmarksArray];
         });
         
         [self getAllBookmarks];
         
        

     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *statusCode = [[operation responseString] justNumbers];
         NSLog(@"status code: %@", statusCode);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationFailed" object:nil];
     }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

-(void)checkForUpdates
{
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"])
    {
        [self getRecentBookmarks];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FirstRun"];
        return;
    }
    
    NSLog(@"check for updates");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CheckingForUpdates" object:nil];
    
    NSString *getString = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/update?auth_token=%@&format=json",  [self apiToken]];
    NSLog(@"%@", getString);
    
    NSURL *url = [NSURL URLWithString:getString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[JSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSLog(@"Response Code: %ld", (long)operation.response.statusCode);
         NSDate *lastRemoteUpdate = QSDateWithString([responseObject objectForKey:@"update_time"]);
         if ([self lastLocalUpdate] != lastRemoteUpdate)
         {
             NSLog(@"There are changes.");
             [[NSUserDefaults standardUserDefaults] setObject:lastRemoteUpdate forKey:@"LastLocalUpdate"];
             [self getRecentBookmarks];
             
         } else
         {
             NSLog(@"Already up to date.");
             [[NSNotificationCenter defaultCenter] postNotificationName:@"NoChangesNeeded" object:nil];
         }
         
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *statusCode = [[operation responseString] justNumbers];
         NSLog(@"status code: %@", statusCode);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationFailed" object:nil];
     }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

-(void)deleteBookmark:(Bookmark *)bookmarkToDelete
{
    NSLog(@"delete bookmark");
    
    if (![self checkTimer:TimerTypeAPI])
    {
        [self performSelector:@selector(deleteBookmark:) withObject:bookmarkToDelete afterDelay:2];
        return;
    }
    
    NSString *encodedURL = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                 NULL,
                                                                                                 (CFStringRef)bookmarkToDelete.url,
                                                                                                 NULL,
                                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                 kCFStringEncodingUTF8 ));
    
    
    NSString *getString = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/delete?auth_token=%@&url=%@&format=json", [self apiToken], encodedURL];
    NSLog(@"%@", getString);
    
    NSURL *url = [NSURL URLWithString:getString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[JSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSLog(@"Response Code: %ld", (long)operation.response.statusCode);
         
         [_context deleteObject:bookmarkToDelete];
         
         [self deleteOrphanedTags];
         [[NSNotificationCenter defaultCenter] postNotificationName:@"BookmarkDeletedSuccessfully" object:bookmarkToDelete];
         
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *statusCode = [[operation responseString] justNumbers];
         NSLog(@"status code: %@", statusCode);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationFailed" object:nil];
     }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

-(void)editBookmark:(Bookmark *)bookmarkToEdit
{
    NSLog(@"edit bookmark");
    
    if (![self checkTimer:TimerTypeAPI])
    {
        [self performSelector:@selector(editBookmark:) withObject:bookmarkToEdit afterDelay:2];
        return;
    }
    
    NSString *encodedURL = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                 NULL,
                                                                                                 (CFStringRef)bookmarkToEdit.url,
                                                                                                 NULL,
                                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                 kCFStringEncodingUTF8 ));
    NSString *encodedDesc = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)bookmarkToEdit.desc,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
    NSString *encodedExtended = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)bookmarkToEdit.extended,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
    NSString *encodedTags = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)bookmarkToEdit.tag,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
    
    NSString *getString = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&url=%@&description=%@&extended=%@&tags=%@&shared=%@&toread=%@&format=json", [self apiToken], encodedURL, encodedDesc, encodedExtended, encodedTags, bookmarkToEdit.shared, bookmarkToEdit.toread];
    NSLog(@"%@", getString);
    NSURL *url = [NSURL URLWithString:getString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[JSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSLog(@"Response Code: %ld", (long)operation.response.statusCode);
         NSArray *tagArray = [[bookmarkToEdit tag] componentsSeparatedByString:@" "];
         
         for (NSString *tag in tagArray)
         {
             NSMutableSet *tagSet = [[NSMutableSet alloc] init];
             
             if (![[tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
             {
                 NSError *error;
                 NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                 [fetchRequest setEntity:[NSEntityDescription entityForName:@"Tag" inManagedObjectContext:_context]];
                 [fetchRequest setFetchLimit:1];
                 [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"name == %@", [tag lowercaseString]]];
                 
                 Tag *newTag;
                 
                 if ([_context countForFetchRequest:fetchRequest error:&error])
                 {
                     newTag = [[_context executeFetchRequest:fetchRequest error:&error] lastObject];
                 } else
                 {
                     newTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:_context];
                 }
                 
                 newTag.name = [tag lowercaseString];
                 [tagSet addObject:newTag];
             }
             
             bookmarkToEdit.tags = [NSSet setWithSet:tagSet];
             
             [self deleteOrphanedTags];
         }
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"BookmarkEditedSuccessfully" object:bookmarkToEdit];
         
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *statusCode = [[operation responseString] justNumbers];
         NSLog(@"status code: %@", statusCode);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationFailed" object:nil];
     }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

-(void)deleteOrphanedTags
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Tag"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"bookmarks.@count < 1"]];
    
    NSError *error;
    NSLog(@"orphans: %lu", (unsigned long)[_context countForFetchRequest:fetchRequest error:&error]);
    
    NSArray *orphans = [_context executeFetchRequest:fetchRequest error:&error];
    
    for (Tag *tag in orphans)
    {
        [_context deleteObject:tag];
    }
}

-(void)addBookmark:(Bookmark *)bookmarkToAdd
{
    NSLog(@"add bookmark");
    
    if (![self checkTimer:TimerTypeAPI])
    {
        [self performSelector:@selector(addBookmark:) withObject:bookmarkToAdd afterDelay:2];
        return;
    }
    
    NSString *encodedURL = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                 NULL,
                                                                                                 (CFStringRef)bookmarkToAdd.url,
                                                                                                 NULL,
                                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                 kCFStringEncodingUTF8 ));
    NSString *encodedDesc = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)bookmarkToAdd.desc,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
    NSString *encodedExtended = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                      NULL,
                                                                                                      (CFStringRef)bookmarkToAdd.extended,
                                                                                                      NULL,
                                                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                      kCFStringEncodingUTF8 ));
    NSString *encodedTags = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                  NULL,
                                                                                                  (CFStringRef)bookmarkToAdd.tag,
                                                                                                  NULL,
                                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                  kCFStringEncodingUTF8 ));
    
    NSString *getString = [NSString stringWithFormat:@"https://api.pinboard.in/v1/posts/add?auth_token=%@&url=%@&description=%@&extended=%@&tags=%@&shared=%@&toread=%@&format=json", [self apiToken], encodedURL, encodedDesc, encodedExtended, encodedTags, bookmarkToAdd.shared, bookmarkToAdd.toread];
    NSLog(@"%@", getString);
    NSURL *url = [NSURL URLWithString:getString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setResponseSerializer:[JSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSLog(@"Response Code: %ld", (long)operation.response.statusCode);
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"BookmarkAddedSuccessfully" object:bookmarkToAdd];
         
     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         NSString *statusCode = [[operation responseString] justNumbers];
         NSLog(@"status code: %@", statusCode);
         [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkOperationFailed" object:nil];
     }];
    
    [[NSOperationQueue mainQueue] addOperation:operation];
}

-(BOOL)performBackgroundUpdate
{
    if (![self checkTimer:TimerTypeAll])
    {
        return NO;
    } else {
        return YES;
    }
}

-(void)logOut
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];

    //NSString *path = [self archivePath];
    //NSURL *storeURL = [NSURL fileURLWithPath:path];
    //NSError *error;
    //[[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
    
    NSError *error;
    NSFetchRequest *allBookmarks = [[NSFetchRequest alloc] initWithEntityName:@"Bookmark"];
    NSFetchRequest *allTags = [[NSFetchRequest alloc] initWithEntityName:@"Tag"];
    
    NSArray *allBookmarksArray = [_context executeFetchRequest:allBookmarks error:&error];
    NSArray *allTagsArray = [_context executeFetchRequest:allTags error:&error];
    
    for (Bookmark *bookmark in allBookmarksArray)
    {
        [_context deleteObject:bookmark];
    }
    
    for (Tag *tag in allTagsArray)
    {
        [_context deleteObject:tag];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LogOutSuccessful" object:nil];
}

@end
