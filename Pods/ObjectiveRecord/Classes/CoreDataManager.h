//
//  CoreDataManager.h
//  WidgetPush
//
//  Created by Marin on 9/1/11.
//  Copyright (c) 2011 mneorr.com. All rights reserved.
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
