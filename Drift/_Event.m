// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.m instead.

#import "_Event.h"

const struct EventAttributes EventAttributes = {
	.guid = @"guid",
	.startDate = @"startDate",
	.stopDate = @"stopDate",
};

const struct EventRelationships EventRelationships = {
	.inRepositories = @"inRepositories",
	.inTag = @"inTag",
};

const struct EventFetchedProperties EventFetchedProperties = {
};

@implementation EventID
@end

@implementation _Event

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Event";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Event" inManagedObjectContext:moc_];
}

- (EventID*)objectID {
	return (EventID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic guid;






@dynamic startDate;






@dynamic stopDate;






@dynamic inRepositories;

	
- (NSMutableSet*)inRepositoriesSet {
	[self willAccessValueForKey:@"inRepositories"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"inRepositories"];
  
	[self didAccessValueForKey:@"inRepositories"];
	return result;
}
	

@dynamic inTag;

	






@end
