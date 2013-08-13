//
//  NSManagedObject+ActiveRecord.h
//  Objective
//
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Mikael Hultgren. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CoreDataManager.h"

@interface NSManagedObjectContext (ActiveRecord)

+ (NSManagedObjectContext *)defaultContext;

@end

@interface NSManagedObject (ActiveRecord)


#pragma mark - Default Context

- (BOOL)save;
- (void)delete;
+ (void)deleteAll;

+ (id)create;

+ (NSArray *)all;
+ (NSArray *)allSortedBy:(id)sortCondition;

+ (id)first;
+ (id)firstWhere:(id)condition;

+ (NSArray *)where:(id)condition;
+ (NSArray *)where:(id)whereCondition sortedBy:(id)sortCondition;
+ (NSArray *)whereFormat:(NSString *)format, ...;


#pragma mark - Custom Context

+ (id)createInContext:(NSManagedObjectContext *)context;

+ (void)deleteAllInContext:(NSManagedObjectContext *)context;

+ (NSArray *)allInContext:(NSManagedObjectContext *)context;
+ (NSArray *)allSortedBy:(id)sortCondition inContext:(NSManagedObjectContext *)context;

+ (NSArray *)where:(id)condition inContext:(NSManagedObjectContext *)context;
+ (NSArray *)where:(id)whereCondition sortedBy:(id)sortCondition inContext:(NSManagedObjectContext *)context;


#pragma mark - Naming

+ (NSString *)entityName;

@end
