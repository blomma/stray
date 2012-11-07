// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Tag.m instead.

#import "_Tag.h"

const struct TagAttributes TagAttributes = {
    .name      = @"name",
    .sortIndex = @"sortIndex",
};

const struct TagRelationships TagRelationships = {
    .heldByEvents            = @"heldByEvents",
    .heldByEventsFilter      = @"heldByEventsFilter",
    .heldByEventsGroupFilter = @"heldByEventsGroupFilter",
};

const struct TagFetchedProperties TagFetchedProperties = {
};

@implementation TagID
@end

@implementation _Tag

+ (id)insertInManagedObjectContext:(NSManagedObjectContext *)moc_ {
    NSParameterAssert(moc_);
    return [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:moc_];
}

+ (NSString *)entityName {
    return @"Tag";
}

+ (NSEntityDescription *)entityInManagedObjectContext:(NSManagedObjectContext *)moc_ {
    NSParameterAssert(moc_);
    return [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:moc_];
}

- (TagID *)objectID {
    return (TagID *)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"sortIndexValue"]) {
        NSSet *affectingKey = [NSSet setWithObject:@"sortIndex"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }

    return keyPaths;
}

@dynamic name;

@dynamic sortIndex;

- (int64_t)sortIndexValue {
    NSNumber *result = [self sortIndex];
    return [result longLongValue];
}

- (void)setSortIndexValue:(int64_t)value_ {
    [self setSortIndex:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveSortIndexValue {
    NSNumber *result = [self primitiveSortIndex];
    return [result longLongValue];
}

- (void)setPrimitiveSortIndexValue:(int64_t)value_ {
    [self setPrimitiveSortIndex:[NSNumber numberWithLongLong:value_]];
}

@dynamic heldByEvents;

- (NSMutableSet *)heldByEventsSet {
    [self willAccessValueForKey:@"heldByEvents"];

    NSMutableSet *result = (NSMutableSet *)[self mutableSetValueForKey:@"heldByEvents"];

    [self didAccessValueForKey:@"heldByEvents"];
    return result;
}

@dynamic heldByEventsFilter;

@dynamic heldByEventsGroupFilter;

@end
