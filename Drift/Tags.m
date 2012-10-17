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
        self.tags = [[NSMutableArray alloc] initWithArray:[tags
                                                           sortedArrayWithOptions:NSSortConcurrent
                                                           usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                               if ([obj1 sortIndex].integerValue < [obj2 sortIndex].integerValue) {
                                                                   return NSOrderedAscending;
                                                               } else if ([obj1 sortIndex].integerValue > [obj2 sortIndex].integerValue) {
                                                                   return NSOrderedDescending;
                                                               } else {
                                                                   return NSOrderedSame;
                                                               }
                                                           }]];
	}

    // Walk over the tags and add sortIndex where it is sorley missed
    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
    }];

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

        [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[Tag class]]) {
                [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
            }
        }];
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

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];

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

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];

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

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];

    return changes;
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self.tags objectAtIndex:index];
}

@end
