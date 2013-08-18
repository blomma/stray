//
//  DropboxRepository.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-16.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "CSV.h"
#import "DropboxRepository.h"
#import "Event.h"
#import "NSDate+Utilities.h"
#import "Repository.h"
#import "State.h"
#import "Tag.h"
#import <Dropbox/Dropbox.h>
#import <THObserversAndBinders.h>

static NSString *const RepositoryName = @"dropbox";

@interface DropboxRepository ()

@property (nonatomic) BOOL isSyncing;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@property (nonatomic) id contextObserver;
@property (nonatomic) id dbSyncStatusObserver;

@end

@implementation DropboxRepository

- (id)init {
	self = [super init];
	if (self) {
		DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:@"70tdvqrgpzmzc6k"
		                                                                     secret:@"4k12ncc57avo9fe"];
		[DBAccountManager setSharedManager:accountManager];

		__weak typeof(self) weakSelf = self;

		self.contextObserver = [[NSNotificationCenter defaultCenter]
		                        addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                object:[NSManagedObjectContext defaultContext]
                                queue:nil
                                usingBlock: ^(NSNotification *note) {
                                    if ([DBAccountManager sharedManager].linkedAccount) {
                                        NSManagedObjectContext *context = [note object];

                                        NSSet *insertedEvents = [[context insertedObjects] objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
                                            return [obj isKindOfClass:[Event class]];
                                        }];

                                        for (Event *event in insertedEvents) {
                                            NSSet *validChanges = [[event changedValues] keysOfEntriesPassingTest: ^BOOL (id key, id obj, BOOL *stop) {
                                                if ([key isEqualToString:@"inRepositories"])
                                                    return NO;

                                                return YES;
                                            }];

                                            NSSet *validChangesSinceLastChanges = [[event changedValuesForCurrentEvent] keysOfEntriesPassingTest: ^BOOL (id key, id obj, BOOL *stop) {
                                                if ([key isEqualToString:@"inRepositories"])
                                                    return NO;

                                                return YES;
                                            }];

                                            if (validChanges.count > 0 && validChangesSinceLastChanges.count > 0) {
                                                Repository *repo = [[event.inRepositories objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
                                                    if ([[obj name] isEqualToString:RepositoryName]) {
                                                        *stop = YES;
                                                        return YES;
                                                    }

                                                    return NO;
                                                }] anyObject];

                                                [weakSelf syncEvent:event withRepo:repo];
                                            }
                                        }

                                        NSSet *updatedEvents = [[context updatedObjects] objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
                                            return [obj isKindOfClass:[Event class]];
                                        }];

                                        for (Event *event in updatedEvents) {
                                            NSSet *validChanges = [[event changedValues] keysOfEntriesPassingTest: ^BOOL (id key, id obj, BOOL *stop) {
                                                if ([key isEqualToString:@"inRepositories"])
                                                    return NO;

                                                return YES;
                                            }];


                                            NSSet *validChangesSinceLastChanges = [[event changedValuesForCurrentEvent] keysOfEntriesPassingTest: ^BOOL (id key, id obj, BOOL *stop) {
                                                if ([key isEqualToString:@"inRepositories"])
                                                    return NO;

                                                return YES;
                                            }];

                                            if (validChanges.count > 0 && validChangesSinceLastChanges.count > 0) {
                                                Repository *repo = [[event.inRepositories objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
                                                    if ([[obj name] isEqualToString:RepositoryName]) {
                                                        *stop = YES;
                                                        return YES;
                                                    }

                                                    return NO;
                                                }] anyObject];

                                                [weakSelf syncEvent:event withRepo:repo];
                                            }
                                        }

                                        NSSet *deletedEvents = [[context deletedObjects] objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
                                            return [obj isKindOfClass:[Event class]];
                                        }];

                                        NSSet *deletedRepositories = [[context deletedObjects] objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
                                            return [obj isKindOfClass:[Repository class]];
                                        }];

                                        for (Event *event in deletedEvents) {
                                            Repository *repo = [[deletedRepositories objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
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
		DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
		[DBFilesystem setSharedFilesystem:filesystem];

		self.isSyncing = (filesystem.status & DBSyncStatusUploading) ==  DBSyncStatusUploading ? YES : NO;

		__weak typeof(self) weakSelf = self;

		[filesystem addObserver:self.dbSyncStatusObserver forPathAndChildren:[DBPath root] block: ^{
		    DBSyncStatus status = [DBFilesystem sharedFilesystem].status;

		    if ((status & DBSyncStatusUploading) ==  DBSyncStatusUploading)
				weakSelf.isSyncing = YES;
		    else
				weakSelf.isSyncing = NO;
		}];
	} else {
		[[DBFilesystem sharedFilesystem] removeObserver:self.dbSyncStatusObserver];
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
	NSArray *events = [Event all];
	for (Event *event in events) {
		Repository *repo = [[event.inRepositories objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
		    if ([[obj name] isEqualToString:RepositoryName]) {
		        *stop = YES;
		        return YES;
			}

		    return NO;
		}] anyObject];

		[self syncEvent:event withRepo:repo];
	}
}

- (void)linkFromController:(id)controller {
	[[DBAccountManager sharedManager] linkFromController:controller];
}

- (void)unLink {
	[self setupWithAccount:nil];
	[[DBAccountManager sharedManager].linkedAccount unlink];
}

#pragma mark -
#pragma mark Private methods

- (void)deleteEvent:(Event *)event withRepo:(Repository *)repo {
	// To maintain backwards compat we try and delete the old name first if no repo exists
	NSString *path = repo ? repo.path : [NSString stringWithFormat:@"%@.csv", event.guid];

	DBError *deleteError;

	DBPath *dbPath = [[DBPath root] childPath:path];
	[[DBFilesystem sharedFilesystem] deletePath:dbPath error:&deleteError];
	DLog(@"%@", deleteError);
}

- (void)syncEvent:(Event *)event withRepo:(Repository *)repo {
	// Save the previous path
	NSString *previousPath = repo ? repo.path : [NSString stringWithFormat:@"%@.csv", event.guid];

	// If no repo then create one
	if (!repo) {
		repo = [Repository create];
        repo.name = RepositoryName;

		[event addInRepositoriesObject:repo];
	}

	NSString *tag = event.inTag.name ? event.inTag.name : @"";
	NSString *startDate = event.startDate ? [event.startDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
	NSString *stopDate = event.stopDate ? [event.stopDate stringByFormat:@"yyyy-MM-dd HH:mm:ss"] : @"";
	NSString *path = [event.startDate stringByFormat:@"yyyy-MM-dd HH-mm-ss"];
    if (event.inTag.name) {
        path = [path stringByAppendingFormat:@"-%@", tag];
    }
    path = [path stringByAppendingString:@".csv"];

	// Check if file exist
	DBError *fileInfoError;
	DBPath *dbPath = [[DBPath root] childPath:previousPath];
	DBFileInfo *fileInfo = [[DBFilesystem sharedFilesystem] fileInfoForPath:dbPath error:&fileInfoError];

    if (fileInfoError) {
        DLog(@"%@ - %@", dbPath, fileInfoError);
    }

	// Remove the file if it exists
	if (fileInfo) {
		DBError *deleteError;
		[[DBFilesystem sharedFilesystem] deletePath:dbPath error:&deleteError];

        if (deleteError) {
            DLog(@"%@ - %@", dbPath, deleteError);
        }
	}

	// Create a new one
	DBError *createError;
	dbPath = [[DBPath root] childPath:path];
	DBFile *dbFile = [[DBFilesystem sharedFilesystem] createFile:dbPath error:&createError];

    if (createError) {
        DLog(@"%@ - %@", dbPath, createError);
    }

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

		DBError *writeError;
		[dbFile writeString:output error:&writeError];

        if (writeError) {
            DLog(@"%@ - %@", dbPath, writeError);
        }

		[dbFile close];

		if (!writeError)
			repo.path = path;
	}
}

@end
