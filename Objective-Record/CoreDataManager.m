//
//  CoreDataManager.m
//  WidgetPush
//
//  Created by Marin on 9/1/11.
//  Copyright (c) 2011 mneorr.com. All rights reserved.
//

#import "CoreDataManager.h"

NSString *const kModelName    = @"CoreDataModel";
NSString *const kDatabaseName = @"CoreDataModel.sqlite";

@interface CoreDataManager ()

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CoreDataManager

+ (id)instance {
    static CoreDataManager *sharedCoreDataManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            sharedCoreDataManager = [[self alloc] init];
        });

    return sharedCoreDataManager;
}

#pragma mark - Public

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        if (self.persistentStoreCoordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        }
    }

    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSString *path = [[NSBundle mainBundle] pathForResource:kModelName
                                                         ofType:@"momd"];
        NSURL *momURL = [NSURL fileURLWithPath:path];

        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    }

    return _managedObjectModel;
}

- (void)setUpPersistentStoreCoordinator {

    NSURL *storeURL = [self.applicationDocumentsDirectory URLByAppendingPathComponent:kDatabaseName];
    NSError *error  = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
        [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error])
        NSLog(@"ERROR IN PERSISTENT STORE COORDINATOR! %@, %@", error, [error userInfo]);
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        [self setUpPersistentStoreCoordinator];
    }

    return _persistentStoreCoordinator;
}

- (BOOL)saveContext {
    if (self.managedObjectContext == nil)
        return NO;

    if (![self.managedObjectContext hasChanges])
        return NO;

    NSError *error = nil;

    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error in saving context! %@, %@", error, [error userInfo]);
        return NO;
    }

    return YES;
}

#pragma mark - Application's Documents directory
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

@end