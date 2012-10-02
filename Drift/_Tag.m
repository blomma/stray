// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Tag.m instead.

#import "_Tag.h"

const struct TagAttributes TagAttributes = {
	.name = @"name",
};

const struct TagRelationships TagRelationships = {
	.heldByEvents = @"heldByEvents",
};

const struct TagFetchedProperties TagFetchedProperties = {
};

@implementation TagID
@end

@implementation _Tag

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Tag";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:moc_];
}

- (TagID*)objectID {
	return (TagID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic heldByEvents;

	
- (NSMutableSet*)heldByEventsSet {
	[self willAccessValueForKey:@"heldByEvents"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"heldByEvents"];
  
	[self didAccessValueForKey:@"heldByEvents"];
	return result;
}
	






@end
