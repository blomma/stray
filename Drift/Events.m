//
//  Events.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-27.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Events.h"

@interface Events ()

@property (nonatomic) NSMutableSet *events;

@property (nonatomic) NSMutableOrderedSet *filteredEvents;
@property (nonatomic) BOOL isFilteredEventsInvalid;

@end

@implementation Events

- (id)init {
	return [self initWithEvents:[NSArray array]];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events {
    self = [super init];
	if (self) {
        self.events = [[NSMutableSet alloc] initWithArray:events];

		self.filteredEvents = [NSMutableOrderedSet orderedSet];
        self.isFilteredEventsInvalid = YES;
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSUInteger)count {
    return self.events.count;
}

- (void)setFilters:(NSSet *)filters {
    _filters = filters;
	self.isFilteredEventsInvalid = YES;
}

- (NSMutableOrderedSet *)filteredEvents {
    if (self.isFilteredEventsInvalid) {
        [_filteredEvents removeAllObjects];
        if (self.filters.count == 0) {
            [_filteredEvents unionSet:self.events];
        } else {
            [_filteredEvents unionSet:[self.events filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"inTag in %@",
                                                                              self.filters]]];
        }

        [_filteredEvents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj2 startDate] compare:[obj1 startDate]];
        }];

        self.isFilteredEventsInvalid = NO;
    }

    return _filteredEvents;
}

#pragma mark -
#pragma mark Public methods

- (void)removeObject:(id)object {
    [self.events removeObject:object];

    if (self.filters.count == 0 || [self.filters containsObject:[object inTag]]) {
        self.isFilteredEventsInvalid = YES;
    }
}

#pragma mark -
#pragma mark Private methods

@end