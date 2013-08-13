//
//  CoreDataManager.m
//  Objective
//
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Mikael Hultgren. All rights reserved.
//

#import "CoreDataManager.h"

@interface CoreDataManager ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CoreDataManager

+ (CoreDataManager *)instance {
	static dispatch_once_t onceToken;
	__strong static id instance = nil;
	dispatch_once(&onceToken, ^{
	    instance = [[self alloc] init];
	});

	return instance;
}

#pragma mark - Private

- (NSString *)modelName {
	if (!_modelName)
		_modelName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

	return _modelName;
}

#pragma mark - Public

- (NSManagedObjectContext *)managedObjectContext {
	if (!_managedObjectContext) {
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	}

	return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	if (!_managedObjectModel) {
		NSURL *url          = [[NSBundle mainBundle] URLForResource:[self modelName] withExtension:@"momd"];
		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
	}

	return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (!_persistentStoreCoordinator)
		_persistentStoreCoordinator = [self persistentStoreCoordinatorWithStoreType:NSSQLiteStoreType
		                                                                   storeURL:[self storeURL]];

	return _persistentStoreCoordinator;
}

- (void)useInMemoryStore {
	_persistentStoreCoordinator = [self persistentStoreCoordinatorWithStoreType:NSInMemoryStoreType
	                                                                   storeURL:nil];
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

#pragma mark - Private

- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorWithStoreType:(NSString *const)storeType storeURL:(NSURL *)storeURL {
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

	NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption:@YES,
		                       NSInferMappingModelAutomaticallyOption:@YES,
		                       NSSQLitePragmasOption: @{ @"journal_mode": @"WAL" }
                               };
	NSError *error = nil;
	NSPersistentStore *store = [coordinator addPersistentStoreWithType:storeType
	                                                     configuration:nil
	                                                               URL:storeURL
	                                                           options:options
	                                                             error:&error];

	if (!store)
		NSLog(@"ERROR WHILE CREATING PERSISTENT STORE COORDINATOR! %@, %@", error, [error userInfo]);

	return coordinator;
}

- (NSURL *)storeURL {
	NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString *storePath = [documentDirectory stringByAppendingPathComponent:[[self modelName] stringByAppendingString:@".sqlite"]];

	return [NSURL fileURLWithPath:storePath];
}

@end
