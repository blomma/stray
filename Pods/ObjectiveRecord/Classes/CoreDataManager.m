//
//  CoreDataManager.m
//  WidgetPush
//
//  Created by Marin on 9/1/11.
//  Copyright (c) 2011 mneorr.com. All rights reserved.
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
	if (_modelName != nil)
		return _modelName;

	_modelName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	return _modelName;
}

#pragma mark - Public

- (NSManagedObjectContext *)managedObjectContext {
	if (_managedObjectContext)
		return _managedObjectContext;

	if (self.persistentStoreCoordinator) {
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	}

	return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	if (_managedObjectModel)
		return _managedObjectModel;

	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self modelName] withExtension:@"momd"];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

	return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (_persistentStoreCoordinator)
		return _persistentStoreCoordinator;

	_persistentStoreCoordinator = [self persistentStoreCoordinatorWithStoreType:NSSQLiteStoreType
	                                                                   storeURL:[self sqliteStoreURL]];
	return _persistentStoreCoordinator;
}

- (void)useInMemoryStore {
	_persistentStoreCoordinator = [self persistentStoreCoordinatorWithStoreType:NSInMemoryStoreType storeURL:nil];
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

	NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @YES,
		                       NSInferMappingModelAutomaticallyOption: @YES };

	NSError *error = nil;
	if (![coordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:options error:&error])
		NSLog(@"ERROR WHILE CREATING PERSISTENT STORE COORDINATOR! %@, %@", error, [error userInfo]);

	return coordinator;
}

- (NSURL *)sqliteStoreURL {
	NSArray *urls           = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
	NSString *pathComponent = [[self modelName] stringByAppendingString:@".sqlite"];

	return [[urls lastObject] URLByAppendingPathComponent:pathComponent];
}

@end
