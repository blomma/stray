// 
//  NSManagedObject+ActiveRecord.m
//  Objective
//  
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Mikael Hultgren. All rights reserved.
// 

#import "NSManagedObject+ActiveRecord.h"

@implementation NSManagedObjectContext (ActiveRecord)

+ (NSManagedObjectContext *)defaultContext {
	return [[CoreDataManager instance] managedObjectContext];
}

@end

@implementation NSManagedObject (ActiveRecord)

#pragma mark - Finders

+ (NSArray *)all {
	return [self allInContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)allSortedBy:(id)sortCondition {
	return [self allSortedBy:sortCondition inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)allInContext:(NSManagedObjectContext *)context {
	return [self allSortedBy:nil inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)allSortedBy:(id)sortCondition inContext:(NSManagedObjectContext *)context {
	NSArray *sortDescriptors = [sortCondition isKindOfClass:[NSArray class]] ? sortCondition : [self sortDescriptorsFromDict:sortCondition];

	return [self fetchWithPredicate:nil withSortDescriptors:sortDescriptors withLimit:0 inContext:context];
}

+ (id)first {
	return [self firstWhere:nil];
}

+ (id)firstWhere:(id)condition {
	NSPredicate *predicate = [condition isKindOfClass:[NSPredicate class]] ? condition : [self predicateFromStringOrDict:condition];
	NSArray *results = [self fetchWithPredicate:predicate withSortDescriptors:nil withLimit:1 inContext:[NSManagedObjectContext defaultContext]];

	return [results objectAtIndex:0];
}

+ (NSArray *)whereFormat:(NSString *)format, ...{
	va_list va_arguments;
	va_start(va_arguments, format);
	NSString *condition = [[NSString alloc] initWithFormat:format arguments:va_arguments];
	va_end(va_arguments);

	return [self where:condition];
}

+ (NSArray *)where:(id)condition {
	return [self where:condition inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)where:(id)whereCondition sortedBy:(id)sortCondition {
	return [self where:whereCondition sortedBy:sortCondition inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)where:(id)condition inContext:(NSManagedObjectContext *)context {
	return [self where:condition sortedBy:nil inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)where:(id)whereCondition sortedBy:(id)sortCondition inContext:(NSManagedObjectContext *)context {
	NSPredicate *predicate = [whereCondition isKindOfClass:[NSPredicate class]] ? whereCondition : [self predicateFromStringOrDict:whereCondition];
	NSArray *sortDescriptors = [sortCondition isKindOfClass:[NSArray class]] ? sortCondition : [self sortDescriptorsFromDict:sortCondition];

	return [self fetchWithPredicate:predicate withSortDescriptors:sortDescriptors withLimit:0 inContext:context];
}

#pragma mark - Creation / Deletion

+ (id)create {
	return [self createInContext:[NSManagedObjectContext defaultContext]];
}

+ (id)createInContext:(NSManagedObjectContext *)context {
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
	                                     inManagedObjectContext:context];
}

- (BOOL)save {
	return [self saveTheContext];
}

- (void)delete {
	[self.managedObjectContext deleteObject:self];
}

+ (void)deleteAll {
	[self deleteAllInContext:[NSManagedObjectContext defaultContext]];
}

+ (void)deleteAllInContext:(NSManagedObjectContext *)context {
    [[self allInContext:context] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj delete];
    }];
}

#pragma mark - Naming

+ (NSString *)entityName {
	return NSStringFromClass(self);
}

#pragma mark - Private

+ (NSString *)queryStringFromDictionary:(NSDictionary *)condition {
	NSMutableString *queryString = [NSMutableString new];

    [condition enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
	    if ([obj isKindOfClass:[NSString class]])
			[queryString appendFormat:@"%@ == %%@", key, obj];
	    else
			[queryString appendFormat:@"%@ == %@", key, obj];

	    if (key == [condition.allKeys lastObject])
            return;

	    [queryString appendString:@" AND "];
    }];

	return queryString;
}

+ (NSPredicate *)predicateFromStringOrDict:(id)condition {
	if ([condition isKindOfClass:[NSString class]])
		return [NSPredicate predicateWithFormat:condition];
	else if ([condition isKindOfClass:[NSDictionary class]])
		return [NSPredicate predicateWithFormat:[self queryStringFromDictionary:condition] argumentArray:[(NSDictionary *)condition allValues]];

	return nil;
}

+ (NSArray *)sortDescriptorsFromDict:(NSDictionary *)condition {
	NSMutableArray *sortDescriptors = [NSMutableArray array];

    [condition enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
	    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:obj];
	    [sortDescriptors addObject:sortDescriptor];
    }];

	return sortDescriptors;
}

+ (NSFetchRequest *)createFetchRequestInContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [NSFetchRequest new];
	NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName]
	                                          inManagedObjectContext:context];
	[request setEntity:entity];

	return request;
}

+ (NSArray *)fetchWithPredicate:(NSPredicate *)predicate
                      inContext:(NSManagedObjectContext *)context {
	return [self fetchWithPredicate:predicate withSortDescriptors:nil withLimit:0 inContext:context];
}

+ (NSArray *)fetchWithPredicate:(NSPredicate *)predicate
            withSortDescriptors:(NSArray *)sortDescriptors
                      withLimit:(NSUInteger)limit
                      inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self createFetchRequestInContext:context];

	[request setFetchLimit:limit];

	if (predicate)
		[request setPredicate:predicate];

	if (sortDescriptors)
		[request setSortDescriptors:sortDescriptors];

	NSArray *fetchedObjects = [context executeFetchRequest:request error:nil];

	return fetchedObjects.count > 0 ? fetchedObjects : nil;
}

- (BOOL)saveTheContext {
	if (self.managedObjectContext == nil || ![self.managedObjectContext hasChanges])
		return YES;

	NSError *error = nil;
	BOOL save = [self.managedObjectContext save:&error];

	if (!save || error) {
		NSLog(@"Unresolved error in saving context for entity:\n%@!\nError: %@", self, error);
		return NO;
	}

	return YES;
}

@end
