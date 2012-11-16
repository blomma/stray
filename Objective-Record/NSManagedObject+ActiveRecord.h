//
//  NSManagedObject+ActiveRecord.h
//  WidgetPush
//
//  Created by Marin Usalj on 4/15/12.
//  Copyright (c) 2012 http://mneorr.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "CoreDataManager.h"
#import "NSArray+Accessors.h"

@interface NSManagedObjectContext (ActiveRecord)

+ (NSManagedObjectContext *)defaultContext;

@end

@interface NSManagedObject (ActiveRecord)

#pragma mark - Default Context

- (BOOL)save;
- (void)delete;
+ (void)deleteAll;

+ (id)create;
+ (id)create:(NSDictionary *)attributes;

+ (NSArray *)all;
+ (NSArray *)where:(id)condition;

#pragma mark - Custom Context

+ (id)createInContext:(NSManagedObjectContext *)context;
+ (id)create:(NSDictionary *)attributes inContext:(NSManagedObjectContext *)context;

+ (void)deleteAllInContext:(NSManagedObjectContext *)context;

+ (NSArray *)allInContext:(NSManagedObjectContext *)context;
+ (NSArray *)where:(id)condition inContext:(NSManagedObjectContext *)context;
+ (NSArray *)where:(id)condition inContext:(NSManagedObjectContext *)context withSortDescriptors:(NSArray *)sortDescriptors;

@end