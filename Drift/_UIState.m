// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to UIState.m instead.

#import "_UIState.h"

const struct UIStateAttributes UIStateAttributes = {
	.name = @"name",
};

const struct UIStateRelationships UIStateRelationships = {
	.activeEvent = @"activeEvent",
	.eventGroupsFilter = @"eventGroupsFilter",
};

const struct UIStateFetchedProperties UIStateFetchedProperties = {
};

@implementation UIStateID
@end

@implementation _UIState

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"UIState" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"UIState";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"UIState" inManagedObjectContext:moc_];
}

- (UIStateID*)objectID {
	return (UIStateID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic activeEvent;

	

@dynamic eventGroupsFilter;

	
- (NSMutableSet*)eventGroupsFilterSet {
	[self willAccessValueForKey:@"eventGroupsFilter"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"eventGroupsFilter"];
  
	[self didAccessValueForKey:@"eventGroupsFilter"];
	return result;
}
	






@end
