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
#import <dispatch/dispatch.h>
#import <Dropbox/Dropbox.h>
#import "CSV.h"
#import "NSDate+Utilities.h"

@interface Canceller : NSObject

@property (nonatomic) BOOL cancel;

@end

@implementation Canceller
@end

@interface DropboxRepository ()

@property (nonatomic) dispatch_queue_t backgroundQueue;
@property (nonatomic) Canceller *canceller;
@property (nonatomic) NSInteger queueCount;

@end

@implementation DropboxRepository

- (id)init {
    self = [super init];
    if (self) {
        self.canceller = [[Canceller alloc] init];
        self.queueCount = 0;

        DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"70tdvqrgpzmzc6k"
                                                                             secret:@"4k12ncc57avo9fe"];
        [DBAccountManager setSharedManager:accountManager];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:[NSManagedObjectContext MR_defaultContext]];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:[NSManagedObjectContext MR_defaultContext]];
}

- (BOOL)isSynced {
    return self.queueCount == 0 ? YES : NO;
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
        
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:[DBAccountManager sharedManager].linkedAccount];
        [DBFilesystem setSharedFilesystem:filesystem];
    } else {
        self.canceller.cancel = YES;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"changeAccount"
                                                        object:self
                                                      userInfo:@{@"account": account ? account : [NSNull null]}];
}

// At this point we have recieved a response, either a account or nil
- (BOOL)handleOpenURL:(NSURL *)url {
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    [self setupWithAccount:account];

    return account ? YES : NO;
}

- (void)sync {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sync"
                                                        object:self
                                                      userInfo:@{@"action": @"start"}];

    NSArray *events = [Event MR_findAll];
    for (Event *event in events) {
        [self deleteEvent:event];
        [self syncEvent:event];
    }

    dispatch_async(self.backgroundQueue, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sync"
                                                            object:self
                                                          userInfo:@{@"action": @"end"}];
    });
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

- (void)deleteEvent:(Event *)event {
    NSString *guid = [event.guid copy];

    self.queueCount += 1;
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.backgroundQueue, ^{
        if (weakSelf.canceller.cancel) {
            weakSelf.queueCount -= 1;
            return;
        }

        DBError *deleteError;
        NSString *fileName = [NSString stringWithFormat:@"%@.csv", guid];
        DBPath *path = [[DBPath root] childPath:fileName];

        [[DBFilesystem sharedFilesystem] deletePath:path error:&deleteError];
        weakSelf.queueCount -= 1;
    });
}

- (void)syncEvent:(Event *)event {
    NSString *guid = [event.guid copy];
    NSString *tag = event.inTag.name ? [event.inTag.name copy ] : @"";
    NSString *startDate = event.startDate ? [event.startDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
    NSString *stopDate = event.stopDate ? [event.stopDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";

    self.queueCount += 1;
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.backgroundQueue, ^{
        if (weakSelf.canceller.cancel) {
            weakSelf.queueCount -= 1;
            return;
        }
        
        DBError *createError;
        NSString *fileName = [NSString stringWithFormat:@"%@.csv", guid];
        DBPath *path = [[DBPath root] childPath:fileName];

        DBFile *file = [[DBFilesystem sharedFilesystem] createFile:path error:&createError];

        if (file) {
            CSVRow *row = [[CSVRow alloc] initWithValues:@[
                           tag,
                           startDate,
                           stopDate
                           ]];

            CSVTable *table = [[CSVTable alloc] initWithRows:@[row]];
            NSMutableString *output = [[NSMutableString alloc] init];
            CSVSerializer *serializer = [[CSVSerializer alloc] initWithOutput:output];
            [serializer serialize:table];

            [file writeString:output error:nil];
        }
        weakSelf.queueCount -= 1;
    });
}

- (void)objectsDidChange:(NSNotification *)note {
    if ([DBAccountManager sharedManager].linkedAccount) {
        NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
        NSSet *deletedObjects  = [[note userInfo] objectForKey:NSDeletedObjectsKey];
        NSSet *updatedObjects  = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

        // ==========
        // = Events =
        // ==========
        NSSet *insertedEvents = [insertedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Event class]];
        }];

        for (Event *event in insertedEvents) {
            [self deleteEvent:event];
            [self syncEvent:event];
        }

        NSSet *updatedEvents = [updatedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Event class]];
        }];

        for (Event *event in updatedEvents) {
            [self deleteEvent:event];
            [self syncEvent:event];
        }

        NSSet *deletedEvents = [deletedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Event class]];
        }];
        
        for (Event *event in deletedEvents) {
            [self deleteEvent:event];
        }
    }
}

@end