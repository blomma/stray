// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to State.m instead.

#import "_State.h"

const struct StateAttributes StateAttributes = {
	.name = @"name",
};

const struct StateRelationships StateRelationships = {
	.inEvent = @"inEvent",
};

const struct StateFetchedProperties StateFetchedProperties = {
};

@implementation StateID
@end

@implementation _State

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"State" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"State";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"State" inManagedObjectContext:moc_];
}

- (StateID*)objectID {
	return (StateID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic inEvent;

	






@end
