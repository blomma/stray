//
//  Tags.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-30.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Tags.h"
#import "Change.h"

@interface Tags ()

@property (nonatomic) NSMutableArray *tags;

@end

@implementation Tags

#pragma mark -
#pragma mark Lifecycle

- (id)init {
	return [self initWithTags:[NSArray array]];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithTags:(NSArray *)tags {
    self = [super init];
	if (self) {
        self.tags = [[NSMutableArray alloc] initWithArray:tags];
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSUInteger)count {
	return self.tags.count;
}

#pragma mark -
#pragma mark Public methods

- (NSSet *)insertObject:(id)object atIndex:(NSUInteger)index {
    NSMutableSet *changes = [NSMutableSet set];

    if (![self.tags containsObject:object]) {
        Change *change = [Change new];
        change.type = ChangeInsert;
        change.object = object;
        change.index = index;

        [changes addObject:change];

        [self.tags insertObject:object atIndex:index];
    }

    return changes;
}

- (NSSet *)removeObjectAtIndex:(NSUInteger)index {
    NSMutableSet *changes = [NSMutableSet set];

    id object = [self.tags objectAtIndex:index];

    Change *change = [Change new];
    change.type = ChangeDelete;
    change.object = object;
    change.index = index;

    [changes addObject:change];

    [self.tags removeObjectAtIndex:index];

    return changes;
}

- (NSSet *)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
    NSMutableSet *changes = [NSMutableSet set];

    Change *change = [Change new];
    change.type = ChangeUpdate;
    change.object = object;
    change.index = index;

    [changes addObject:change];

    [self.tags replaceObjectAtIndex:index withObject:object];

    return changes;
}

- (NSSet *)moveObjectAtIndex:(NSUInteger)atIndex toIndex:(NSUInteger)toIndex {
    NSMutableSet *changes = [NSMutableSet set];

    id object = [self.tags objectAtIndex:atIndex];

    // This is a remove/insert operation
    Change *change = [Change new];
    change.type = ChangeDelete;
    change.object = object;
    change.index = atIndex;

    [changes addObject:change];
    [self.tags removeObjectAtIndex:atIndex];

    
    change = [Change new];
    change.type = ChangeInsert;
    change.object = object;
    change.index = toIndex;

    [changes addObject:change];
    [self.tags insertObject:object atIndex:toIndex];

    return changes;
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self.tags objectAtIndex:index];
}

@end
