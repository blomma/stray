//
//  Tags.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-30.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Tags.h"

@interface Tags ()

@property (nonatomic) NSMutableOrderedSet *tags;
@property (nonatomic) BOOL isTagsInvalid;

@end

@implementation Tags

- (id)init {
	return [self initWithTags:[NSArray array]];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithTags:(NSArray *)tags {
    self = [super init];
	if (self) {
        self.tags = [[NSMutableOrderedSet alloc] initWithArray:[tags
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

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSUInteger)count {
	return self.tags.count;
}

#pragma mark -
#pragma mark Public methods

- (void)addObjectsFromArray:(NSArray *)objects {
    if (objects.count == 0) {
        return;
    }

    [self.tags addObjectsFromArray:objects];

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];
}

- (void)removeObjectsInArray:(NSArray *)objects {
    if (objects.count == 0) {
        return;
    }

    [self.tags removeObjectsInArray:objects];

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
    if (![self.tags containsObject:object]) {
        [self.tags insertObject:object atIndex:index];

        [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[Tag class]]) {
                [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
            }
        }];
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [self.tags removeObjectAtIndex:index];

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
    [self.tags replaceObjectAtIndex:index withObject:object];

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];
}

- (void)moveObjectAtIndex:(NSUInteger)atIndex toIndex:(NSUInteger)toIndex {
    id object = [self.tags objectAtIndex:atIndex];

    [self.tags removeObjectAtIndex:atIndex];
    [self.tags insertObject:object atIndex:toIndex];

    [self.tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[Tag class]]) {
            [obj setSortIndex:[NSNumber numberWithInteger:(NSInteger)idx]];
        }
    }];
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self.tags objectAtIndex:index];
}

- (NSUInteger)indexOfObject:(id)object {
    return [self.tags indexOfObject:object];
}

@end
