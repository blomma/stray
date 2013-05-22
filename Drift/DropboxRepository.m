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

@interface DropboxRepository ()

@property (nonatomic) dispatch_queue_t backgroundQueue;

@end

@implementation DropboxRepository

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundQueue = dispatch_queue_create("com.artsoftheinsane.Stray.bgqueue", NULL);

        DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"70tdvqrgpzmzc6k"
                                                                             secret:@"4k12ncc57avo9fe"];
        [DBAccountManager setSharedManager:accountManager];
    }

    return self;
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

- (void)setup {
    if ([DBAccountManager sharedManager].linkedAccount) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:[DBAccountManager sharedManager].linkedAccount];
        [DBFilesystem setSharedFilesystem:filesystem];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(objectsDidChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:[NSManagedObjectContext MR_defaultContext]];
}


#pragma mark -
#pragma mark Public methods

- (BOOL)handleOpenURL:(NSURL *)url {
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
    }

    return account ? YES : NO;
}

- (void)sync {
    NSArray *events = [Event MR_findAll];
    for (Event *event in events) {
        NSString *guid = [event.guid copy];
        NSString *tag = event.inTag.name ? [event.inTag.name copy ] : @"";
        NSString *startDate = event.startDate ? [event.startDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
        NSString *stopDate = event.stopDate ? [event.stopDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";

        dispatch_async(self.backgroundQueue, ^{
            DBError *deleteError, *createError;
            NSString *fileName = [NSString stringWithFormat:@"%@.csv", guid];
            DBPath *path = [[DBPath root] childPath:fileName];

            // First we remove the old file if it exists
            [[DBFilesystem sharedFilesystem] deletePath:path error:&deleteError];

            // Then we create the new file
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
}

#pragma mark -
#pragma mark Private methods

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
        NSString *guid = [event.guid copy];
        NSString *tag = event.inTag.name ? [event.inTag.name copy ] : @"";
        NSString *startDate = event.startDate ? [event.startDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
        NSString *stopDate = event.stopDate ? [event.stopDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";

        dispatch_async(self.backgroundQueue, ^{
            DBError *deleteError, *createError;
            NSString *fileName = [NSString stringWithFormat:@"%@.csv", guid];
            DBPath *path = [[DBPath root] childPath:fileName];

            // First we remove the old file if it exists
            [[DBFilesystem sharedFilesystem] deletePath:path error:&deleteError];

            // Then we create the new file
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

    NSSet *updatedEvents = [updatedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }];

    for (Event *event in updatedEvents) {
        NSString *guid = [event.guid copy];
        NSString *tag = event.inTag.name ? [event.inTag.name copy ] : @"";
        NSString *startDate = event.startDate ? [event.startDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
        NSString *stopDate = event.stopDate ? [event.stopDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";

        dispatch_async(self.backgroundQueue, ^{
            DBError *deleteError, *createError;
            NSString *fileName = [NSString stringWithFormat:@"%@.csv", guid];
            DBPath *path = [[DBPath root] childPath:fileName];

            // First we remove the old file if it exists
            [[DBFilesystem sharedFilesystem] deletePath:path error:&deleteError];

            // Then we create the new file
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

    NSSet *deletedEvents = [deletedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }];

    for (Event *event in deletedEvents) {
        NSString *guid = [event.guid copy];
        dispatch_async(self.backgroundQueue, ^{
            DBError *deleteError;
            NSString *fileName = [NSString stringWithFormat:@"%@.csv", guid];
            DBPath *path = [[DBPath root] childPath:fileName];
            [[DBFilesystem sharedFilesystem] deletePath:path error:&deleteError];
        });
    }
}

@end