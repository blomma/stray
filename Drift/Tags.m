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

- (NSSet *)addTag:(Tag *)tag {
    return [self addTags:@[tag]];
}

- (NSSet *)addTags:(NSArray *)tags {
    NSMutableArray *changes = [NSMutableArray array];

    for (Tag *tag in tags) {
        if (![self.tags containsObject:tag]) {
            [self.tags addObject:tag];

            Change *change = [Change new];
            change.type = ChangeInsert;
            change.object = tag;

            [changes addObject:change];
        }
    }

    for (Change *change in changes) {
        NSUInteger i = [self.tags indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
            return [obj isEqual:change.object];
        }];
        change.index = i;
    }

    return [NSSet setWithArray:changes];
}

- (NSSet *)removeTag:(Tag *)tag {
    return [self removeTags:@[tag]];
}

- (NSSet *)removeTags:(NSArray *)tags {
    NSMutableSet *changes = [NSMutableSet set];

    // First find the indexes of the tags to be removed
    for (Tag *tag in tags) {
        NSUInteger index = [self.tags indexOfObject:tag];
        if (index != NSNotFound) {
            Change *change = [Change new];
            change.type = ChangeDelete;
            change.index = index;
            change.object = tag;

            [changes addObject:change];
        }
    }

    [self.tags removeObjectsInArray:tags];

    return changes;
}

- (Tag *)tagAtIndex:(NSUInteger)index {
    return [self.tags objectAtIndex:index];
}

- (NSUInteger)indexOfTag:(Tag *)tag {
    return [self.tags indexOfObject:tag];
}

@end
