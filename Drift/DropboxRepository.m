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

@end

@implementation DropboxRepository

- (id)init {
    self = [super init];
    if (self) {
        self.canceller = [[Canceller alloc] init];

        DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"70tdvqrgpzmzc6k"
                                                                             secret:@"4k12ncc57avo9fe"];
        [DBAccountManager setSharedManager:accountManager];
    }

    return self;
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
    if (!self.backgroundQueue) {
        self.backgroundQueue = dispatch_queue_create("com.artsoftheinsane.stray.bgqueue", NULL);
    }
    
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:[DBAccountManager sharedManager].linkedAccount];
        [DBFilesystem setSharedFilesystem:filesystem];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:[NSManagedObjectContext MR_defaultContext]];
    }
    
}

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
    self.canceller.cancel = YES;
    [[DBAccountManager sharedManager].linkedAccount unlink];
}

#pragma mark -
#pragma mark Private methods

- (void)deleteEvent:(Event *)event {
    NSString *guid = [event.guid copy];

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.backgroundQueue, ^{
        if (weakSelf.canceller.cancel) {
            return;
        }

        DBError *deleteError;
        NSString *fileName = [NSString stringWithFormat:@"%@.csv", guid];
        DBPath *path = [[DBPath root] childPath:fileName];

        [[DBFilesystem sharedFilesystem] deletePath:path error:&deleteError];
    });
}

- (void)syncEvent:(Event *)event {
    NSString *guid = [event.guid copy];
    NSString *tag = event.inTag.name ? [event.inTag.name copy ] : @"";
    NSString *startDate = event.startDate ? [event.startDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
    NSString *stopDate = event.stopDate ? [event.stopDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.backgroundQueue, ^{
        if (weakSelf.canceller.cancel) {
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
    });
}

- (void)objectsDidChange:(NSNotification *)note {
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

@end