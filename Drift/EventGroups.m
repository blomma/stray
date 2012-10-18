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
#import "Change.h"
#import "DataManager.h"
#import "Global.h"

@interface EventGroups ()

@property (nonatomic) NSMutableArray *events;

@property (nonatomic) NSMutableArray *allEventGroups;
@property (nonatomic) NSMutableArray *filteredEventGroups;
@property (nonatomic) BOOL filteredEventGroupsIsInvalid;

@property (nonatomic) NSCalendar *calendar;

@end

@implementation EventGroups

#pragma mark -
#pragma mark Lifecycle

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events filter:(Tag *)tag {
    self = [super init];
	if (self) {
        self.events      = [[NSMutableArray alloc] initWithArray:events];
        self.allEventGroups = [NSMutableArray new];
        self.filteredEventGroups = [NSMutableArray new];

        self.calendar = [Global instance].calendar;

        for (Event *event in events) {
            [self addEvent:event];
        }

        self.filter = tag;
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (void)setFilter:(Tag *)filter {
    if ([filter isEqual:_filter]) {
        return;
    }

    _filter = filter;

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

- (NSSet *)addEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet set];

    if (![self.events containsObject:event]) {
        [self.events addObject:event];
    }

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
		EventGroup *eventGroup;
        NSUInteger index = [self indexForGroupDate:startDate];

        if (index == NSNotFound) {
            eventGroup = [[EventGroup alloc] initWithDate:startDate];
        } else {
            eventGroup = [self.allEventGroups objectAtIndex:index];
        }

		// Check if this eventGroup already has this event
		if (![eventGroup containsEvent:event]) {
			Change *change = [Change new];

			if (index == NSNotFound) {
                change.type = ChangeInsert;

                index = [self insertionIndexForGroupDate:eventGroup.groupDate];
                [self.allEventGroups insertObject:eventGroup atIndex:index];
			} else {
                change.type = ChangeUpdate;
                change.index = index;
			}

            change.object = eventGroup;

            [changes unionSet:[eventGroup addEvent:event]];
			[changes addObject:change];
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

    // Update insert index for EventGroups
    for (Change *change in changes) {
        if ([change.type isEqualToString:ChangeInsert] && [change.object isKindOfClass:[EventGroup class]]) {
            NSUInteger i = [self.allEventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
                return [obj isEqual:change.object];
            }];
            change.index = i;
        }
    }

    if (!self.filter || [event.inTag isEqual:self.filter]) {
        self.filteredEventGroupsIsInvalid = YES;
    }

	return changes;
}

- (NSSet *)removeEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet set];

    [self.events removeObject:event];

    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (NSUInteger i = 0; i < self.allEventGroups.count; i++) {
        EventGroup *eventGroup = [self.allEventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event]) {
            [changes unionSet:[eventGroup removeEvent:event]];

            Change *change = [Change new];
            change.object  = eventGroup;
            change.type  = eventGroup.count > 0 ? ChangeUpdate : ChangeDelete;
            change.index = i;

            if ([change.type isEqualToString:ChangeDelete]) {
                [indexesToRemove addIndex:i];
            }

			[changes addObject:change];
		}
	}

    // Remove empty groups
    [self.allEventGroups removeObjectsAtIndexes:indexesToRemove];
    
    if (!self.filter || [event.inTag isEqual:self.filter]) {
        self.filteredEventGroupsIsInvalid = YES;
    }

    return changes;
}

- (NSSet *)updateEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet set];

    for (NSUInteger i = 0; i < self.allEventGroups.count; i++) {
        EventGroup *eventGroup = [self.allEventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event] && [eventGroup isValidForEvent:event]) {
			Change *change = [Change new];
			change.object  = eventGroup;
			change.type  = ChangeUpdate;
            change.index = i;

            [changes unionSet:[eventGroup updateEvent:event]];
			[changes addObject:change];
		}
	}

	// Insert event into any groups that can contain it, possibly creating new groups for this
    [changes unionSet:[self addEvent:event]];

    // Next we remove the event from invalid eventGroups
    [changes unionSet:[self removeFromInvalidGroupsEvent:event]];

    if (!self.filter || [event.inTag isEqual:self.filter]) {
        self.filteredEventGroupsIsInvalid = YES;
    }

	return changes;
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

    for (EventGroup *eventGroup in self.allEventGroups) {
        eventGroup.filter = self.filter;
        if (eventGroup.filteredEvents.count > 0) {
            [self.filteredEventGroups addObject:eventGroup];
        }
    }

    self.filteredEventGroupsIsInvalid = NO;
}

- (NSSet *)removeFromInvalidGroupsEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet set];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (NSUInteger i = 0; i < self.allEventGroups.count; i++) {
        EventGroup *eventGroup = [self.allEventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event] && ![eventGroup isValidForEvent:event]) {
            [changes unionSet:[eventGroup removeEvent:event]];

            Change *change = [Change new];
            change.object  = eventGroup;
            change.type  = eventGroup.count > 0 ? ChangeUpdate : ChangeDelete;
            change.index = i;

            if ([change.type isEqualToString:ChangeDelete]) {
                [indexesToRemove addIndex:i];
            }

			[changes addObject:change];
		}
	}

    // Remove empty groups
    [self.allEventGroups removeObjectsAtIndexes:indexesToRemove];

	return changes;
}

- (NSUInteger)indexForGroupDate:(NSDate *)date {
    NSDate *groupDate = [date beginningOfDayWithCalendar:self.calendar];

    NSUInteger index = [self.allEventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        if ([[obj groupDate] isEqualToDate:groupDate]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    return index;
}

- (NSUInteger)insertionIndexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.allEventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        if ([[obj groupDate] compare:date] == NSOrderedAscending) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index == NSNotFound) {
        index = self.allEventGroups.count;
    }
    
    return index;
}

@end