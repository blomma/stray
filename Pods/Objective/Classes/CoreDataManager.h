// 
//  CoreDataManager.h
//  Objective
//  
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Mikael Hultgren. All rights reserved.
// 

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataManager : NSObject

@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSString *databaseName;
@property (nonatomic) NSString *modelName;

+ (id)instance;
- (BOOL)saveContext;
- (void)useInMemoryStore;

#pragma mark - Helpers

- (NSURL *)applicationDocumentsDirectory;

@end
