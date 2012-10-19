//
//  EventGroups.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroups.h"
#import "NSDate+Utilities.h"
#import "Tag.h"
#import "DataManager.h"
#import "Global.h"

@interface EventGroups ()

@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSMutableArray *eventGroups;
@property (nonatomic) NSMutableArray *filteredEventGroups;
@property (nonatomic) BOOL filteredEventGroupsIsInvalid;

@end

@implementation EventGroups

#pragma mark -
#pragma mark Lifecycle

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events withFilters:(NSSet *)filters {
    self = [super init];
	if (self) {
        self.calendar = [Global instance].calendar;

        self.eventGroups         = [NSMutableArray new];
        self.filteredEventGroups = [NSMutableArray new];

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
    self.filteredEventGroupsIsInvalid = YES;
}

- (NSUInteger)count {
    if (self.filteredEventGroupsIsInvalid) {
        [self updateFilteredEventGroups];
    }

    return self.filteredEventGroups.count;
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
	unsigned int unitFlags = NSSecondCalendarUnit;
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
        NSUInteger index = [self indexForGroupDate:groupDate];

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

            [eventGroup addEvent:event];
		}

		// We want to add the delta between the startDate day and end of startDate day
		// this only nets us enough delta to make it to the end of the day so
		// we need to add one second to this to tip it over
		NSDate *endOfDay = [startDate endOfDayWithCalendar:self.calendar];
		NSDateComponents *deltaSecondsComponent = [self.calendar components:unitFlags
                                                                   fromDate:startDate
                                                                     toDate:endOfDay
                                                                    options:0];
		deltaSecondsComponent.second += 1;

		totalSecondsComponent.second += deltaSecondsComponent.second;
		eventSecondsComponent.second -= deltaSecondsComponent.second;
	}

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.filteredEventGroupsIsInvalid = YES;
    }
}

- (void)removeEvent:(Event *)event {
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event]) {
            [eventGroup removeEvent:event];

            if (eventGroup.count == 0) {
                [indexesToRemove addIndex:i];
            }

		}
	}

    // Remove empty groups
    [self.eventGroups removeObjectsAtIndexes:indexesToRemove];
    
    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.filteredEventGroupsIsInvalid = YES;
    }
}

- (void)updateEvent:(Event *)event {
	NSDate *startDate = [event.startDate beginningOfDayWithCalendar:self.calendar];
	NSDate *stopDate = [event isActive] ? [NSDate date] : event.stopDate;

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

        if ([[eventGroup groupDate] earlierDate:event.startDate]) {
            break;
        }

		if ([eventGroup containsEvent:event] && [eventGroup.groupDate isBetweenDate:startDate andDate:stopDate]) {
            [eventGroup updateEvent:event];
		}
	}

	// Insert event into any groups that can contain it, possibly creating new groups for this
    [self addEvent:event];

    // Next we remove the event from invalid eventGroups
    [self removeFromInvalidGroupsEvent:event];

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.filteredEventGroupsIsInvalid = YES;
    }
}

- (id)objectAtIndex:(NSUInteger)index {
    if (self.filteredEventGroupsIsInvalid) {
        [self updateFilteredEventGroups];
    }
    return [self.filteredEventGroups objectAtIndex:index];
}

#pragma mark -
#pragma mark Private methods

- (void)updateFilteredEventGroups {
    [self.filteredEventGroups removeAllObjects];

    for (EventGroup *eventGroup in self.eventGroups) {
        eventGroup.filters = self.filters;
        if (eventGroup.filteredEvents.count > 0) {
            [self.filteredEventGroups addObject:eventGroup];
        }
    }

    self.filteredEventGroupsIsInvalid = NO;
}

- (void)removeFromInvalidGroupsEvent:(Event *)event {
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

	NSDate *startDate = [event.startDate beginningOfDayWithCalendar:self.calendar];
	NSDate *stopDate = [event isActive] ? [NSDate date] : event.stopDate;

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event] && ![eventGroup.groupDate isBetweenDate:startDate andDate:stopDate]) {
            [eventGroup removeEvent:event];

            if (eventGroup.count == 0) {
                [indexesToRemove addIndex:i];
            }
		}
	}

    // Remove empty groups
    [self.eventGroups removeObjectsAtIndexes:indexesToRemove];
}

- (NSUInteger)indexForGroupDate:(NSDate *)groupDate {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        if ([[obj groupDate] isEqualToDate:groupDate]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    return index;
}

- (NSUInteger)insertionIndexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
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