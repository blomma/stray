// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.m instead.

#import "_Event.h"

const struct EventAttributes EventAttributes = {
	.exported = @"exported",
	.guid = @"guid",
	.startDate = @"startDate",
	.stopDate = @"stopDate",
};

const struct EventRelationships EventRelationships = {
	.inTag = @"inTag",
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

	if ([key isEqualToString:@"exportedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"exported"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}

@dynamic exported;

- (BOOL)exportedValue {
	NSNumber *result = [self exported];
	return [result boolValue];
}

- (void)setExportedValue:(BOOL)value_ {
	[self setExported:@(value_)];
}

- (BOOL)primitiveExportedValue {
	NSNumber *result = [self primitiveExported];
	return [result boolValue];
}

- (void)setPrimitiveExportedValue:(BOOL)value_ {
	[self setPrimitiveExported:@(value_)];
}

@dynamic guid;

@dynamic startDate;

@dynamic stopDate;

@dynamic inTag;

@end

