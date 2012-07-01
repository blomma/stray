// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.m instead.

#import "_Event.h"

const struct EventAttributes EventAttributes = {
	.running = @"running",
	.runningTimeHours = @"runningTimeHours",
	.runningTimeMilliseconds = @"runningTimeMilliseconds",
	.runningTimeMinutes = @"runningTimeMinutes",
	.runningTimeSeconds = @"runningTimeSeconds",
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
	if ([key isEqualToString:@"runningTimeHoursValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"runningTimeHours"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"runningTimeMillisecondsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"runningTimeMilliseconds"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"runningTimeMinutesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"runningTimeMinutes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"runningTimeSecondsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"runningTimeSeconds"];
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





@dynamic runningTimeHours;



- (int64_t)runningTimeHoursValue {
	NSNumber *result = [self runningTimeHours];
	return [result longLongValue];
}

- (void)setRunningTimeHoursValue:(int64_t)value_ {
	[self setRunningTimeHours:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveRunningTimeHoursValue {
	NSNumber *result = [self primitiveRunningTimeHours];
	return [result longLongValue];
}

- (void)setPrimitiveRunningTimeHoursValue:(int64_t)value_ {
	[self setPrimitiveRunningTimeHours:[NSNumber numberWithLongLong:value_]];
}





@dynamic runningTimeMilliseconds;



- (int16_t)runningTimeMillisecondsValue {
	NSNumber *result = [self runningTimeMilliseconds];
	return [result shortValue];
}

- (void)setRunningTimeMillisecondsValue:(int16_t)value_ {
	[self setRunningTimeMilliseconds:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveRunningTimeMillisecondsValue {
	NSNumber *result = [self primitiveRunningTimeMilliseconds];
	return [result shortValue];
}

- (void)setPrimitiveRunningTimeMillisecondsValue:(int16_t)value_ {
	[self setPrimitiveRunningTimeMilliseconds:[NSNumber numberWithShort:value_]];
}





@dynamic runningTimeMinutes;



- (int16_t)runningTimeMinutesValue {
	NSNumber *result = [self runningTimeMinutes];
	return [result shortValue];
}

- (void)setRunningTimeMinutesValue:(int16_t)value_ {
	[self setRunningTimeMinutes:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveRunningTimeMinutesValue {
	NSNumber *result = [self primitiveRunningTimeMinutes];
	return [result shortValue];
}

- (void)setPrimitiveRunningTimeMinutesValue:(int16_t)value_ {
	[self setPrimitiveRunningTimeMinutes:[NSNumber numberWithShort:value_]];
}





@dynamic runningTimeSeconds;



- (int16_t)runningTimeSecondsValue {
	NSNumber *result = [self runningTimeSeconds];
	return [result shortValue];
}

- (void)setRunningTimeSecondsValue:(int16_t)value_ {
	[self setRunningTimeSeconds:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveRunningTimeSecondsValue {
	NSNumber *result = [self primitiveRunningTimeSeconds];
	return [result shortValue];
}

- (void)setPrimitiveRunningTimeSecondsValue:(int16_t)value_ {
	[self setPrimitiveRunningTimeSeconds:[NSNumber numberWithShort:value_]];
}





@dynamic startDate;






@dynamic stopDate;






@dynamic tag;











@end
