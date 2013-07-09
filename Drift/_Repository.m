// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Repository.m instead.

#import "_Repository.h"

const struct RepositoryAttributes RepositoryAttributes = {
	.lastSynced = @"lastSynced",
	.name = @"name",
	.path = @"path",
};

const struct RepositoryRelationships RepositoryRelationships = {
	.heldByEvent = @"heldByEvent",
};

const struct RepositoryFetchedProperties RepositoryFetchedProperties = {
};

@implementation RepositoryID
@end

@implementation _Repository

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Repository" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Repository";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Repository" inManagedObjectContext:moc_];
}

- (RepositoryID*)objectID {
	return (RepositoryID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic lastSynced;






@dynamic name;






@dynamic path;






@dynamic heldByEvent;

	






@end
