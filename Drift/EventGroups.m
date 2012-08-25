//
//  EventGroups.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroup.h"
#import "EventGroupChange.h"
#import "EventGroups.h"
#import "NSDate+Utilities.h"

@interface EventGroups ()

@property (nonatomic) NSMutableArray *eventGroups;
@property (nonatomic) NSCalendar *calendar;

@end

@implementation EventGroups

- (id)init {
	return [self initWithEvents:[NSArray array]];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events {
	if ((self = [super init])) {
		self.eventGroups = [NSMutableArray array];
        self.calendar    = [NSCalendar currentCalendar];

        [self addEvents:events];
	}

	return self;
}

#pragma mark -
#pragma mark Public instance methods

- (void)addEvents:(NSArray *)events {
    for (Event *event in events) {
        NSDate *startDate = event.startDate;
        NSDate *stopDate  = event.stopDate;

        // Is the event running, if so set the stopDate to now
        if (event.isActiveValue) {
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
                if (index == NSNotFound) {
                    index = [self insertionIndexForGroupDate:eventGroup.groupDate];
                    [self.eventGroups insertObject:eventGroup atIndex:index];
                }

                // Add the event
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
    }

    [self.eventGroups sortUsingSelector:@selector(reverseCompare:)];

	[self updateExistsActiveEventGroup];
}

- (NSArray *)addEvent:(Event *)event {
	NSDate *startDate = event.startDate;
	NSDate *stopDate  = event.stopDate;

	// Is the event running, if so set the stopDate to now
	if (event.isActiveValue) {
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

	NSMutableArray *changes = [NSMutableArray array];

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
		NSUInteger i = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
			return [[(EventGroup *) obj GUID] isEqualToString:eventGroupChange.GUID];
		}];

		eventGroupChange.index = i;
	}

	[self updateExistsActiveEventGroup];
    
	return [changes copy];
}

- (NSArray *)removeEvent:(Event *)event withConditionIsInvalid:(BOOL)condition {
	NSMutableArray *changes = [NSMutableArray array];

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		BOOL process = [eventGroup containsEvent:event];

		// Check if condition is given and if so only remove event if it is invalid
		if (condition && process && [eventGroup isValidForEvent:event]) {
			process = NO;
		}

		if (process) {
			EventGroupChange *eventGroupChange = [EventGroupChange new];
			eventGroupChange.GUID  = eventGroup.GUID;
			eventGroupChange.type  = EventGroupChangeUpdate;
            eventGroupChange.index = i;
            
			[changes addObject:eventGroupChange];

			[eventGroup removeEvent:event];
		}
	}

	for (EventGroupChange *eventGroupChange in changes) {
		// We cant trust the index, so we look it up again
		NSUInteger i = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
			return [[(EventGroup *) obj GUID] isEqualToString:eventGroupChange.GUID];
		}];

		EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];
		if (eventGroup.count == 0) {
			eventGroupChange.type = EventGroupChangeDelete;

			[self.eventGroups removeObjectAtIndex:i];
		}
	}

	[self updateExistsActiveEventGroup];

	return [changes copy];
}

- (NSArray *)updateEvent:(Event *)event withConditionIsActive:(BOOL)condition {
	NSMutableArray *changes = [NSMutableArray array];

	// Update the event in any groups that contains it and can contain it, later we remove it from invalid groups
    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];
		BOOL process = [eventGroup containsEvent:event] && [eventGroup isValidForEvent:event];

		// Check if condition is given and if so only update if it is active
		if (condition && !eventGroup.isActive) {
			process = NO;
		}

		if (process) {
			EventGroupChange *eventGroupChange = [EventGroupChange new];
			eventGroupChange.GUID  = eventGroup.GUID;
			eventGroupChange.type  = EventGroupChangeUpdate;
            eventGroupChange.index = i;

			[changes addObject:eventGroupChange];

			[eventGroup updateEvent:event];
		}
	}

	// Remove this event from any groups that it no longer can be in
	NSArray *deleteChanges = [self removeEvent:event withConditionIsInvalid:YES];
	[changes addObjectsFromArray:deleteChanges];

	// Insert event into any groups that can contain it, possibly creating new groups for this
	NSArray *insertChanges = [self addEvent:event];
	[changes addObjectsFromArray:insertChanges];

	[self updateExistsActiveEventGroup];

	return [changes copy];
}

- (NSUInteger)count {
	return self.eventGroups.count;
}

- (EventGroup *)eventGroupAtIndex:(NSUInteger)index {
	return [self.eventGroups objectAtIndex:index];
}

- (NSUInteger)indexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        return [(EventGroup *) obj canContainDate:date];
    }];

    return index;
}

- (NSUInteger)indexForActiveGroupEvent {
	if (self.eventGroups.count > 0) {
		EventGroup *eventGroup = [self.eventGroups objectAtIndex:0];
		if (eventGroup.isActive) {
			return 0;
		}
	}

    return NSNotFound;
}

#pragma mark -
#pragma mark Private instance methods

- (NSUInteger)insertionIndexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        return [[(EventGroup *) obj groupDate] compare:date] == NSOrderedAscending;
    }];

    if (index == NSNotFound) {
        index = self.eventGroups.count;
    }

    return index;
}

- (void)updateExistsActiveEventGroup {
    NSUInteger index = [self indexForActiveGroupEvent];
    self.existsActiveEventGroup = (index == NSNotFound ? NO : YES);
}


@end