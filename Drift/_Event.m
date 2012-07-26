// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.m instead.

#import "_Event.h"

const struct EventAttributes EventAttributes = {
	.running = @"running",
	.startDate = @"startDate",
	.stopDate = @"stopDate",
	.tag = @"tag",
};

const struct EventRelationships EventRelationships = {
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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"runningValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"running"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic running;



- (BOOL)runningValue {
	NSNumber *result = [self running];
	return [result boolValue];
}

- (void)setRunningValue:(BOOL)value_ {
	[self setRunning:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveRunningValue {
	NSNumber *result = [self primitiveRunning];
	return [result boolValue];
}

- (void)setPrimitiveRunningValue:(BOOL)value_ {
	[self setPrimitiveRunning:[NSNumber numberWithBool:value_]];
}





@dynamic startDate;






@dynamic stopDate;






@dynamic tag;











@end
