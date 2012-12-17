//
//  EventsGroupedByStartDate.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsGroupedByStartDate.h"

#import "NSDate+Utilities.h"
#import "Global.h"
#import "EventGroup.h"

@interface EventsGroupedByStartDate ()

@property (nonatomic) NSMutableArray *eventGroups;

@property (nonatomic) NSMutableArray *filteredEventGroups;
@property (nonatomic) BOOL isFilteredEventGroupsInvalid;

@property (nonatomic) NSMapTable *eventToEventGroupsMap;
@end

@implementation EventsGroupedByStartDate

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events withFilters:(NSSet *)filters {
    self = [super init];
    if (self) {
        self.eventGroups         = [NSMutableArray new];
        self.filteredEventGroups = [NSMutableArray new];

        self.eventToEventGroupsMap = [NSMapTable weakToWeakObjectsMapTable];

        for (Event *event in events) {
            [self addEvent:event];
        }

        self.filters = filters;
    }

    return self;
}

#pragma mark -
#pragma mark Public properties

- (void)setFilters:(NSSet *)filters {
    _filters = filters;

    self.isFilteredEventGroupsInvalid = YES;
}

- (NSMutableArray *)filteredEventGroups {
    if (self.isFilteredEventGroupsInvalid) {
        [_filteredEventGroups removeAllObjects];

        for (EventGroup *eventGroup in self.eventGroups) {
            eventGroup.filters = self.filters;

            if (eventGroup.filteredEvents.count > 0) {
                [_filteredEventGroups addObject:eventGroup];
            }
        }

        self.isFilteredEventGroupsInvalid = NO;
    }

    return _filteredEventGroups;
}

#pragma mark -
#pragma mark Public methods

- (void)addEvent:(Event *)event {
    NSDate *groupDate = [event.startDate beginningOfDayWithCalendar:[Global instance].calendar];
    NSUInteger index  = [self indexForGroupDate:groupDate];

    EventGroup *eventGroup = nil;
    if (index == NSNotFound) {
        eventGroup = [[EventGroup alloc] initWithGroupDate:groupDate];
    } else {
        eventGroup = [self.eventGroups objectAtIndex:index];
    }

    // Check if this eventGroup already has this event
    if (![eventGroup containsEvent:event]) {
        if (index == NSNotFound) {
            index = [self insertionIndexForGroupDate:groupDate];
            [self.eventGroups insertObject:eventGroup atIndex:index];
        }

        [self.eventToEventGroupsMap setObject:eventGroup forKey:event];

        [eventGroup addEvent:event];
    }

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.isFilteredEventGroupsInvalid = YES;
    }
}

- (void)removeEvent:(Event *)event {
    EventGroup *eventGroup = [self.eventToEventGroupsMap objectForKey:event];
    if (!eventGroup) {
        return;
    }

    [eventGroup removeEvent:event];

    if (eventGroup.count == 0) {
        [self.eventGroups removeObject:eventGroup];
    }

    [self.eventToEventGroupsMap removeObjectForKey:event];

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.isFilteredEventGroupsInvalid = YES;
    }
}

- (void)updateEvent:(Event *)event {
    EventGroup *eventGroup = [self.eventToEventGroupsMap objectForKey:event];
    if (!eventGroup) {
        return;
    }

    NSDate *groupDate = [event.startDate beginningOfDayWithCalendar:[Global instance].calendar];

    if ([eventGroup.groupDate isEqualToDate:groupDate]) {
        [eventGroup updateEvent:event];
    } else {
        [eventGroup removeEvent:event];
        [self.eventToEventGroupsMap removeObjectForKey:event];

        if (eventGroup.count == 0) {
            [self.eventGroups removeObject:eventGroup];
        }

        [self addEvent:event];
    }

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.isFilteredEventGroupsInvalid = YES;
    }
}

#pragma mark -
#pragma mark Filtered methods

- (NSUInteger)filteredEventGroupCount {
    return self.filteredEventGroups.count;
}

- (id)filteredEventAtIndexPath:(NSIndexPath *)indexPath {
    EventGroup *eventGroup = [self.filteredEventGroups objectAtIndex:(NSUInteger)indexPath.section];
    return [eventGroup.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];
}

- (NSIndexPath *)indexPathOfFilteredEvent:(Event *)event {
    NSIndexPath *indexPath = nil;
    EventGroup *eventGroup = [self.eventToEventGroupsMap objectForKey:event];

    if (eventGroup) {
        NSUInteger indexOfEventGroup = [self.filteredEventGroups indexOfObject:eventGroup];
        NSUInteger indexOfEvent      = [eventGroup.filteredEvents indexOfObject:event];
        indexPath = [NSIndexPath indexPathForRow:(NSInteger)indexOfEvent inSection:(NSInteger)indexOfEventGroup];
    }

    return indexPath;
}

- (id)filteredEventGroupAtIndex:(NSUInteger)index {
    return [self.filteredEventGroups objectAtIndex:index];
}

#pragma mark -
#pragma mark Private methods

- (NSUInteger)indexForGroupDate:(NSDate *)groupDate {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
            if ([[obj groupDate] isEqualToDate:groupDate]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];

    return index;
}

- (NSUInteger)insertionIndexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
            if ([[obj groupDate] compare:date] == NSOrderedAscending) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];

    if (index == NSNotFound) {
        index = self.eventGroups.count;
    }

    return index;
}

@end