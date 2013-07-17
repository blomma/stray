//
//  NSManagedObject+ActiveRecord.h
//  WidgetPush
//
//  Created by Marin Usalj on 4/15/12.
//  Copyright (c) 2012 http://mneorr.com. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSManagedObject+Mappings.h"
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
+ (id)create:(NSDictionary *)attributes;
- (void)update:(NSDictionary *)attributes;

+ (NSArray *)all;
+ (NSArray *)allSortedBy:(id)sortCondition;

+ (id)first;
+ (id)firstWhere:(id)condition;

+ (NSArray *)where:(id)condition;
+ (NSArray *)where:(id)whereCondition sortedBy:(id)sortCondition;
+ (NSArray *)whereFormat:(NSString *)format, ...;


#pragma mark - Custom Context

+ (id)createInContext:(NSManagedObjectContext *)context;
+ (id)create:(NSDictionary *)attributes inContext:(NSManagedObjectContext *)context;

+ (void)deleteAllInContext:(NSManagedObjectContext *)context;

+ (NSArray *)allInContext:(NSManagedObjectContext *)context;
+ (NSArray *)allSortedBy:(id)sortCondition inContext:(NSManagedObjectContext *)context;

+ (NSArray *)where:(id)condition inContext:(NSManagedObjectContext *)context;
+ (NSArray *)where:(id)whereCondition sortedBy:(id)sortCondition inContext:(NSManagedObjectContext *)context;


#pragma mark - Naming

+ (NSString *)entityName;

@end
