//
//  EventGroups.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroups.h"

#import "NSDate+Utilities.h"
#import "Global.h"
#import "EventGroup.h"

@interface EventGroups ()

@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSMutableArray *eventGroups;

@property (nonatomic) NSMutableArray *filteredEventGroups;
@property (nonatomic) BOOL isFilteredEventGroupsInvalid;

@property (nonatomic) NSMapTable *eventToEventGroupsMap;
@end

@implementation EventGroups

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events withFilters:(NSSet *)filters {
    self = [super init];
    if (self) {
        self.calendar = [Global instance].calendar;

        self.eventGroups         = [NSMutableArray new];
        self.filteredEventGroups = [NSMutableArray new];

        self.eventToEventGroupsMap = [NSMapTable weakToStrongObjectsMapTable];

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
    NSDate *startDate = event.startDate;
    NSDate *stopDate  = event.stopDate;

    // Is the event running, if so set the stopDate to now
    if ([event isActive]) {
        stopDate = [NSDate date];
    }

    // Calculate how many seconds this event spans
    unsigned int unitFlags                  = NSSecondCalendarUnit;
    NSDateComponents *eventSecondsComponent = [self.calendar components:unitFlags
                                                               fromDate:startDate
                                                                 toDate:stopDate
                                                                options:0];

    NSDateComponents *totalSecondsComponent = [[NSDateComponents alloc] init];
    totalSecondsComponent.second = 0;

    // Loop over it until there are no more future time left in it
    while (eventSecondsComponent.second >= 0) {
        startDate = [self.calendar dateByAddingComponents:totalSecondsComponent
                                                   toDate:event.startDate
                                                  options:0];

        // Find a EventGroup for this startDate
        NSDate *groupDate = [startDate beginningOfDayWithCalendar:self.calendar];
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

            NSMutableSet *eventGroups = [self.eventToEventGroupsMap objectForKey:event];
            if (!eventGroups) {
                eventGroups = [NSMutableSet set];
                [self.eventToEventGroupsMap setObject:eventGroups forKey:event];
            }
            [eventGroups addObject:eventGroup];

            [eventGroup addEvent:event];
        }

        // We want to add the delta between the startDate day and end of startDate day
        // this only nets us enough delta to make it to the end of the day so
        // we need to add one second to this to tip it over
        NSDate *endOfDay                        = [startDate endOfDayWithCalendar:self.calendar];
        NSDateComponents *deltaSecondsComponent = [self.calendar components:unitFlags
                                                                   fromDate:startDate
                                                                     toDate:endOfDay
                                                                    options:0];
        deltaSecondsComponent.second += 1;

        totalSecondsComponent.second += deltaSecondsComponent.second;
        eventSecondsComponent.second -= deltaSecondsComponent.second;
    }

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.isFilteredEventGroupsInvalid = YES;
    }
}

- (void)removeEvent:(Event *)event {
    NSMutableSet *eventGroups = [self.eventToEventGroupsMap objectForKey:event];
    if (!eventGroups) {
        return;
    }

    for (EventGroup *eventGroup in eventGroups) {
        [eventGroup removeEvent:event];

        if (eventGroup.count == 0) {
            [self.eventGroups removeObject:eventGroup];
        }
    }

    [self.eventToEventGroupsMap removeObjectForKey:event];

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.isFilteredEventGroupsInvalid = YES;
    }
}

- (void)updateEvent:(Event *)event {
    NSMutableSet *eventGroups = [self.eventToEventGroupsMap objectForKey:event];
    if (!eventGroups) {
        return;
    }

    NSDate *startDate = [event.startDate beginningOfDayWithCalendar:self.calendar];
    NSDate *stopDate  = [event isActive] ? [NSDate date] : event.stopDate;

    NSMutableSet *eventGroupsToRemove = [NSMutableSet set];
    for (EventGroup *eventGroup in eventGroups) {
        if ([eventGroup.groupDate isBetweenDate:startDate andDate:stopDate]) {
            [eventGroup updateEvent:event];
        } else {
            [eventGroup removeEvent:event];
            [eventGroupsToRemove addObject:eventGroup];

            if (eventGroup.count == 0) {
                [self.eventGroups removeObject:eventGroup];
            }
        }
    }

    [eventGroups minusSet:eventGroupsToRemove];

    [self addEvent:event];

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.isFilteredEventGroupsInvalid = YES;
    }
}

#pragma mark -
#pragma mark Filtered methods

- (id)filteredObjectAtIndex:(NSUInteger)index {
    return [self.filteredEventGroups objectAtIndex:index];
}

- (NSUInteger)filteredCount {
    return self.filteredEventGroups.count;
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