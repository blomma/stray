//
//  DropboxRepository.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-16.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "DropboxRepository.h"
#import "Event.h"
#import "Tag.h"
#import "Repository.h"
#import <dispatch/dispatch.h>
#import <Dropbox/Dropbox.h>
#import "CSV.h"
#import "NSDate+Utilities.h"
#import <THObserversAndBinders.h>
#import "State.h"

static NSString *const RepositoryName = @"dropbox";

@interface Canceller : NSObject

@property (nonatomic) BOOL cancel;

@end

@implementation Canceller
@end

@interface DropboxRepository ()

@property (nonatomic) BOOL isSyncing;

@property (nonatomic) dispatch_queue_t backgroundQueue;
@property (nonatomic) Canceller *canceller;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@property (nonatomic) id contextObserver;
@property (nonatomic) id dbSyncStatusObserver;

@end

@implementation DropboxRepository

- (id)init {
    self = [super init];
    if (self) {
        self.canceller = [[Canceller alloc] init];

        DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"70tdvqrgpzmzc6k"
                                                                             secret:@"4k12ncc57avo9fe"];
        [DBAccountManager setSharedManager:accountManager];

        __weak typeof(self) weakSelf = self;
        self.contextObserver = [[NSNotificationCenter defaultCenter]
                                addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                            object:[NSManagedObjectContext MR_defaultContext]
                                             queue:nil
                                        usingBlock:^(NSNotification *note) {
            if ([DBAccountManager sharedManager].linkedAccount) {
                NSManagedObjectContext *context = [note object];

                NSSet *insertedEvents = [[context insertedObjects] objectsPassingTest:^BOOL (id obj, BOOL *stop) {
                    return [obj isKindOfClass:[Event class]];
                }];

                for (Event *event in insertedEvents) {
                    NSSet *validChanges = [[event changedValues] keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
                        if ([key isEqualToString:@"inRepositories"]) {
                            return NO;
                        }

                        return YES;
                    }];

                    NSSet *validChangesSinceLastChanges = [[event changedValuesForCurrentEvent] keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
                        if ([key isEqualToString:@"inRepositories"]) {
                            return NO;
                        }
                        
                        return YES;
                    }];

                    if (validChanges.count > 0 && validChangesSinceLastChanges.count > 0) {
                        [weakSelf deleteEvent:event];
                        [weakSelf syncEvent:event];
                    }
                }

                NSSet *updatedEvents = [[context updatedObjects] objectsPassingTest:^BOOL (id obj, BOOL *stop) {
                        return [obj isKindOfClass:[Event class]];
                    }];

                for (Event *event in updatedEvents) {
                    NSSet *validChanges = [[event changedValues] keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
                        if ([key isEqualToString:@"inRepositories"]) {
                            return NO;
                        }

                        return YES;
                    }];


                    NSSet *validChangesSinceLastChanges = [[event changedValuesForCurrentEvent] keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
                        if ([key isEqualToString:@"inRepositories"]) {
                            return NO;
                        }

                        return YES;
                    }];

                    if (validChanges.count > 0 && validChangesSinceLastChanges.count > 0) {
                        [weakSelf deleteEvent:event];
                        [weakSelf syncEvent:event];
                    }
                }

                NSSet *deletedEvents = [[context deletedObjects] objectsPassingTest:^BOOL (id obj, BOOL *stop) {
                    return [obj isKindOfClass:[Event class]];
                }];

                NSSet *deletedRepositories = [[context deletedObjects] objectsPassingTest:^BOOL (id obj, BOOL *stop) {
                    return [obj isKindOfClass:[Repository class]];
                }];

                for (Event *event in deletedEvents) {
                    Repository *repo = [[deletedRepositories objectsPassingTest:^BOOL(id obj, BOOL *stop) {
                        if ([[obj name] isEqualToString:RepositoryName]) {
                            *stop = YES;
                            return YES;
                        }

                        return NO;
                    }] anyObject];

                    [weakSelf deleteEvent:event withRepo:repo];
                }
            }
        }];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.contextObserver];
}

#pragma mark -
#pragma mark Class methods

- (DBAccount *)account {
    return [DBAccountManager sharedManager].linkedAccount;
}

#pragma mark -
#pragma mark Class methods

+ (DropboxRepository *)instance {
    static DropboxRepository *sharedDropboxRepository = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDropboxRepository = [[self alloc] init];
    });

    return sharedDropboxRepository;
}

#pragma mark -
#pragma mark Public methods

- (void)setupWithAccount:(DBAccount *)account {
    if (account) {
        self.canceller.cancel = NO;

        if (!self.backgroundQueue) {
            self.backgroundQueue = dispatch_queue_create("com.artsoftheinsane.stray.bgqueue", NULL);
        }

        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];

        self.isSyncing = (filesystem.status & DBSyncStatusUploading) ==  DBSyncStatusUploading ? YES : NO;

        __weak typeof(self) weakSelf = self;
        [filesystem addObserver:self.dbSyncStatusObserver forPathAndChildren:[DBPath root] block:^{
            DBSyncStatus status = [DBFilesystem sharedFilesystem].status;

            if ((status & DBSyncStatusUploading) ==  DBSyncStatusUploading) {
                weakSelf.isSyncing = YES;
            } else {
                weakSelf.isSyncing = NO;
            }
        }];
    } else {
        [[DBFilesystem sharedFilesystem] removeObserver:self.dbSyncStatusObserver];
        self.canceller.cancel = YES;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeAccount"
                                                        object:self
                                                      userInfo:@{ @"account":account ? account : [NSNull null] }];
}

// At this point we have recieved a response, either a account or nil
- (BOOL)handleOpenURL:(NSURL *)url {
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    [self setupWithAccount:account];

    return account ? YES : NO;
}

- (void)sync {
    NSArray *events = [Event MR_findAll];
    for (Event *event in events) {
        [self deleteEvent:event];
        [self syncEvent:event];
    }
}

- (void)link {
    [[DBAccountManager sharedManager] linkFromController:[[[UIApplication sharedApplication] keyWindow] rootViewController]];
}

- (void)unLink {
    [self setupWithAccount:nil];
    [[DBAccountManager sharedManager].linkedAccount unlink];
}

#pragma mark -
#pragma mark Private methods

- (void)beginBackgroundTask {
    __weak typeof(self) weakSelf = self;
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [weakSelf endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
}

- (void)deleteEvent:(Event *)event {
    NSSet *repos = [event.inRepositories objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        if ([[obj name] isEqualToString:RepositoryName]) {
            *stop = YES;
            return YES;
        }

        return NO;
    }];

    Repository *repo = [repos anyObject];

    [self deleteEvent:event withRepo:repo];
}

- (void)deleteEvent:(Event *)event withRepo:(Repository *)repo {
    [self beginBackgroundTask];

    // To maintain backwards compat we try and delete the old name first if no repo exists
    NSString *path = [NSString stringWithFormat:@"%@.csv", event.guid];
    if (repo) {
        path = [repo.path copy];
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.backgroundQueue, ^{
        if (weakSelf.canceller.cancel) {
            return;
        }

        DBError *deleteError;

        DBPath *dbPath = [[DBPath root] childPath:path];
        [[DBFilesystem sharedFilesystem] deletePath:dbPath error:&deleteError];
    });

    [self endBackgroundTask];
}

- (void)syncEvent:(Event *)event {
    [self beginBackgroundTask];

    NSSet *repos = [event.inRepositories objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        if ([[obj name] isEqualToString:RepositoryName]) {
            *stop = YES;
            return YES;
        }

        return NO;
    }];

    Repository *repo = [repos anyObject];

    // If no repo then create one
    if (!repo) {
        repo = [Repository MR_createEntity];
        repo.name = RepositoryName;

        [event addInRepositoriesObject:repo];
    }

    NSString *tag = event.inTag.name ? [event.inTag.name copy ] : @"";
    NSString *startDate = event.startDate ? [event.startDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
    NSString *stopDate = event.stopDate ? [event.stopDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
    NSString *path = [NSString stringWithFormat:@"%@-%@.csv", [event.startDate stringByFormat:@"yyyy-MM-dd HHmmss"], event.guid];

    // Update the pathname to the potential new filename
    repo.path = path;

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.backgroundQueue, ^{
        if (weakSelf.canceller.cancel) {
            return;
        }

        DBError *createError;
            
        DBPath *dbPath = [[DBPath root] childPath:path];
        DBFile *dbFile = [[DBFilesystem sharedFilesystem] createFile:dbPath error:&createError];

        if (dbFile) {
            CSVRow *row = [[CSVRow alloc] initWithValues:
                           @[
                             tag,
                             startDate,
                             stopDate
                             ]];

            CSVTable *table = [[CSVTable alloc] initWithRows:@[row]];
            NSMutableString *output = [[NSMutableString alloc] init];
            CSVSerializer *serializer = [[CSVSerializer alloc] initWithOutput:output];
            [serializer serialize:table];

            [dbFile writeString:output error:&createError];
            [dbFile close];
        }
    });

    [self endBackgroundTask];
}

@end