//
//  EventGroups.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"
#import "EventGroupChange.h"
#import "EventGroups.h"
#import "NSDate+Utilities.h"
#import "Tag.h"

@interface EventGroups ()

@property (nonatomic) NSMutableArray *events;
@property (nonatomic) NSMutableArray *eventGroups;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic, readwrite) EventGroup *activeEventGroup;
@property (nonatomic) BOOL activeEventGroupIsInvalid;

@end

@implementation EventGroups

#pragma mark -
#pragma mark Lifecycle

- (id)init {
	return [self initWithEvents:[NSArray array]];
}

- (id)initWithEvents:(NSArray *)events {
	return [self initWithEvents:events filter:nil];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events filter:(Tag *)tag {
    self = [super init];
	if (self) {
        self.events      = [[NSMutableArray alloc] initWithArray:events];
        self.eventGroups = [NSMutableArray array];
        self.calendar    = [NSCalendar currentCalendar];

        [self filterOnTag:tag];
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSUInteger)count {
	return self.eventGroups.count;
}

- (EventGroup *)activeEventGroup {
    if (self.activeEventGroupIsInvalid) {
        [self updateActiveEventGroup];
    }

    return _activeEventGroup;
}

#pragma mark -
#pragma mark Public methods

- (NSArray *)addEvent:(Event *)event {
	NSMutableArray *changes = [NSMutableArray array];

    if (![self.events containsObject:event]) {
        [self.events addObject:event];
    }

    if (self.filter && ![event.inTag isEqual:self.filter]) {
        return changes;
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
            eventGroup = [self.eventGroups objectAtIndex:index];
        }

		// Check if this eventGroup already has this event
		if (index == NSNotFound || ![eventGroup containsEvent:event]) {
			EventGroupChange *eventGroupChange = [EventGroupChange new];

			if (index == NSNotFound) {
                eventGroupChange.type = EventGroupChangeInsert;

                index = [self insertionIndexForGroupDate:eventGroup.groupDate];
                [self.eventGroups insertObject:eventGroup atIndex:index];
			} else {
                eventGroupChange.type = EventGroupChangeUpdate;
                eventGroupChange.index = index;
			}

			// Add the event
			[eventGroup addEvent:event];

            eventGroupChange.GUID = eventGroup.GUID;

			// Add the change
			[changes addObject:eventGroupChange];
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

    for (EventGroupChange *eventGroupChange in changes) {
        if ([eventGroupChange.type isEqualToString:EventGroupChangeInsert]) {
            NSUInteger i = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
                return [[(EventGroup *) obj GUID] isEqualToString:eventGroupChange.GUID];
            }];
            eventGroupChange.index = i;
        }
    }

    self.activeEventGroupIsInvalid = YES;

	return [changes copy];
}

- (NSArray *)removeEvent:(Event *)event {
    [self.events removeObject:event];

    return [self removeFromGroupsEvent:event];
}

- (NSArray *)updateEvent:(Event *)event {
	NSMutableArray *changes = [NSMutableArray array];

    // If this event doesnt even fullfill the tag filter then we just need to remove it and be done
    if (self.filter && ![event.inTag isEqual:self.filter]) {
        [changes addObjectsFromArray:[self removeFromGroupsEvent:event]];

        return changes;
    }

    // Otherwise, we start with updating the events that needs updating
    // but only the evetgroups that are valid for this event
    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event] && [eventGroup isValidForEvent:event]) {
			EventGroupChange *eventGroupChange = [EventGroupChange new];
			eventGroupChange.GUID  = eventGroup.GUID;
			eventGroupChange.type  = EventGroupChangeUpdate;
            eventGroupChange.index = i;

			[changes addObject:eventGroupChange];

			[eventGroup updateEvent:event];
		}
	}

    // Next we remove the event from invalid eventGroups
    [changes addObjectsFromArray:[self removeFromInvalidGroupsEvent:event]];

	// Insert event into any groups that can contain it, possibly creating new groups for this
	[changes addObjectsFromArray:[self addEvent:event]];

    self.activeEventGroupIsInvalid = YES;

	return [changes copy];
}

- (NSArray *)filterOnTag:(Tag *)tag {
    NSMutableArray *changes = [NSMutableArray array];

    for (Event *event in self.events) {
        if (tag && ![event.inTag isEqual:tag]) {
            // Remove if tag is not nill and the event is not a match
            [changes addObjectsFromArray:[self removeFromGroupsEvent:event]];
        } else {
            // Readd the event, the underlying code will handle if the event already exists
            [changes addObjectsFromArray:[self addEvent:event]];
        }
    }

    self.filter = tag;

    return [changes copy];
}

- (EventGroup *)eventGroupAtIndex:(NSUInteger)index {
	return [self.eventGroups objectAtIndex:index];
}

#pragma mark -
#pragma mark Private methods

- (NSArray *)removeFromGroupsEvent:(Event *)event {
	NSMutableArray *changes = [NSMutableArray array];

    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event]) {
			EventGroupChange *eventGroupChange = [self removeEvent:event fromGroup:eventGroup];
            eventGroupChange.index = i;

            if ([eventGroupChange.type isEqualToString:EventGroupChangeDelete]) {
                [indexesToRemove addIndex:i];
            }

			[changes addObject:eventGroupChange];
		}
	}

    // Remove empty groups
    [self.eventGroups removeObjectsAtIndexes:indexesToRemove];

    self.activeEventGroupIsInvalid = YES;

	return [changes copy];
}

- (NSArray *)removeFromInvalidGroupsEvent:(Event *)event {
	NSMutableArray *changes = [NSMutableArray array];

    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event] && ![eventGroup isValidForEvent:event]) {
			EventGroupChange *eventGroupChange = [self removeEvent:event fromGroup:eventGroup];
            eventGroupChange.index = i;

            if ([eventGroupChange.type isEqualToString:EventGroupChangeDelete]) {
                [indexesToRemove addIndex:i];
            }

			[changes addObject:eventGroupChange];
		}
	}

    // Remove empty groups
    [self.eventGroups removeObjectsAtIndexes:indexesToRemove];

    self.activeEventGroupIsInvalid = YES;

	return [changes copy];
}

- (EventGroupChange *)removeEvent:(Event *)event fromGroup:(EventGroup *)eventGroup {
    [eventGroup removeEvent:event];

    EventGroupChange *eventGroupChange = [EventGroupChange new];
    eventGroupChange.GUID  = eventGroup.GUID;
    eventGroupChange.type  = eventGroup.count > 0 ? EventGroupChangeUpdate : EventGroupChangeDelete;

    return eventGroupChange;
}

- (NSUInteger)indexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        return [[(EventGroup *)obj groupDate] isEqualToDateIgnoringTime:date withCalendar:self.calendar];
    }];

    return index;
}

- (NSUInteger)insertionIndexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        return [[(EventGroup *)obj groupDate] compare:date] == NSOrderedAscending;
    }];

    if (index == NSNotFound) {
        index = self.eventGroups.count;
    }
    
    return index;
}

- (void)updateActiveEventGroup {
    self.activeEventGroup = nil;
    
	if (self.eventGroups.count > 0) {
		EventGroup *eventGroup = [self.eventGroups objectAtIndex:0];
		if (eventGroup.activeEvent) {
            self.activeEventGroup = eventGroup;
		}
	}
}


@end