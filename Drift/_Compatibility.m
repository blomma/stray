// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Compatibility.m instead.

#import "_Compatibility.h"

const struct CompatibilityAttributes CompatibilityAttributes = {
	.level = @"level",
};

const struct CompatibilityRelationships CompatibilityRelationships = {
};

const struct CompatibilityFetchedProperties CompatibilityFetchedProperties = {
};

@implementation CompatibilityID
@end

@implementation _Compatibility

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Compatibility" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Compatibility";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Compatibility" inManagedObjectContext:moc_];
}

- (CompatibilityID*)objectID {
	return (CompatibilityID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"levelValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"level"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic level;



- (int64_t)levelValue {
	NSNumber *result = [self level];
	return [result longLongValue];
}

- (void)setLevelValue:(int64_t)value_ {
	[self setLevel:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveLevelValue {
	NSNumber *result = [self primitiveLevel];
	return [result longLongValue];
}

- (void)setPrimitiveLevelValue:(int64_t)value_ {
	[self setPrimitiveLevel:[NSNumber numberWithLongLong:value_]];
}










@end
