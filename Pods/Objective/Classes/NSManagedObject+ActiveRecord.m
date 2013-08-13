// 
//  NSManagedObject+ActiveRecord.m
//  Objective
//  
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Mikael Hultgren. All rights reserved.
// 

#import "NSManagedObject+ActiveRecord.h"
#import "ObjectiveSugar.h"

@implementation NSManagedObjectContext (ActiveRecord)

+ (NSManagedObjectContext *)defaultContext {
	return [[CoreDataManager instance] managedObjectContext];
}

@end

@implementation NSObject (null)

- (BOOL)exists {
	return self && self != [NSNull null];
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

+ (id)create:(NSDictionary *)attributes {
	return [self create:attributes inContext:[NSManagedObjectContext defaultContext]];
}

+ (id)create:(NSDictionary *)attributes inContext:(NSManagedObjectContext *)context {
	unless([attributes exists]) return nil;

	NSManagedObject *newEntity = [self createInContext:context];
	[newEntity update:attributes];

	return newEntity;
}

+ (id)createInContext:(NSManagedObjectContext *)context {
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
	                                     inManagedObjectContext:context];
}

- (void)update:(NSDictionary *)attributes {
	unless([attributes exists]) return;

	[attributes each: ^(id key, id value) {
	    id remoteKey = [self keyForRemoteKey:key];

	    if ([remoteKey isKindOfClass:[NSString class]])
			[self setSafeValue:value forKey:remoteKey];
	    else
			[self hydrateObject:value ofClass:remoteKey[@"class"] forKey:remoteKey[@"key"] ? :key];
	}];
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
	[[self allInContext:context] each: ^(id object) {
	    [object delete];
	}];
}

#pragma mark - Naming

+ (NSString *)entityName {
	return NSStringFromClass(self);
}

#pragma mark - Private

+ (NSString *)queryStringFromDictionary:(NSDictionary *)conditions {
	NSMutableString *queryString = [NSMutableString new];

	[conditions each: ^(id attribute, id value) {
	    if ([value isKindOfClass:[NSString class]])
			[queryString appendFormat:@"%@ == %%@", attribute, value];
	    else
			[queryString appendFormat:@"%@ == %@", attribute, value];

	    if (attribute == conditions.allKeys.last) return;
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

	[condition each: ^(id attribute, id value) {
	    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:attribute ascending:value];
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

- (void)hydrateObject:(id)properties ofClass:(Class)class forKey:(NSString *)key {
	[self setSafeValue:[self objectOrSetOfObjectsFromValue:properties ofClass:class]
	            forKey:key];
}

- (id)objectOrSetOfObjectsFromValue:(id)value ofClass:(Class)class {
	if ([value isKindOfClass:[NSArray class]])
		return [NSSet setWithArray:[value map: ^id (NSDictionary *dict) {
		    return [class create:dict inContext:self.managedObjectContext];
		}]];

	else return [class create:value inContext:self.managedObjectContext];
}

- (void)setSafeValue:(id)value forKey:(id)key {
	if (value == nil || value == [NSNull null]) return;

	NSDictionary *attributes = [[self entity] attributesByName];
	NSAttributeType attributeType = [[attributes objectForKey:key] attributeType];

	if ((attributeType == NSStringAttributeType) && ([value isKindOfClass:[NSNumber class]])) {
		value = [value stringValue];
	} else if ([value isKindOfClass:[NSString class]]) {
		if ([self isIntegerAttributeType:attributeType])
			value = [NSNumber numberWithInteger:[value integerValue]];

		else if (attributeType == NSFloatAttributeType)
			value = [NSNumber numberWithDouble:[value doubleValue]];

		else if (attributeType == NSDateAttributeType)
			value = [self.defaultFormatter dateFromString:value];
	}

	[self setValue:value forKey:key];
}

- (BOOL)isIntegerAttributeType:(NSAttributeType)attributeType {
	return (attributeType == NSInteger16AttributeType) ||
    (attributeType == NSInteger32AttributeType) ||
    (attributeType == NSInteger64AttributeType) ||
    (attributeType == NSBooleanAttributeType);
}

#pragma mark - Date Formatting

- (NSDateFormatter *)defaultFormatter {
	static NSDateFormatter *sharedFormatter;
	static dispatch_once_t singletonToken;
	dispatch_once(&singletonToken, ^{
	    sharedFormatter = [[NSDateFormatter alloc] init];
	    [sharedFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
	});

	return sharedFormatter;
}

@end
