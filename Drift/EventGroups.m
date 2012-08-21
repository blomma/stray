//
//  EventGroups.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroups.h"

#import "Event.h"
#import "EventGroup.h"
#import "EventGroupChange.h"
#import "NSDate+Utilities.h"

@interface EventGroups ()

@property (nonatomic) NSMutableArray *eventGroups;

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

		for (Event *event in events) {
			// TODO: Create an optimized version of addEvent that doesnt return a change set for use here
			[self addEvent:event];
		}
	}

	return self;
}

#pragma mark -
#pragma mark Public instance methods

- (NSArray *)addEvent:(Event *)event {
	DLog(@"start self.eventGroups.count %d", self.eventGroups.count);

	NSDate *startDate = event.startDate;
	NSDate *stopDate  = event.stopDate;

	// Is the event running, if so set the stopDate to now
	if (event.isActiveValue) {
		stopDate = [NSDate date];
	}

	NSCalendar *calender = [NSCalendar currentCalendar];

	// Calculate how many seconds this event spans
	unsigned int unitFlags = NSSecondCalendarUnit;
	NSDateComponents *eventSecondsComponent = [calender components:unitFlags
														  fromDate:startDate
															toDate:stopDate
														   options:0];

	NSDateComponents *totalSecondsComponent = [[NSDateComponents alloc] init];
	totalSecondsComponent.second = 0;

	NSMutableArray *changes = [NSMutableArray array];

	// Loop over it until there are no more future time left in it
	DLog(@"eventSecondsComponent %@", eventSecondsComponent.description);

	while (eventSecondsComponent.second >= 0) {
		startDate = [calender dateByAddingComponents:totalSecondsComponent
											  toDate:event.startDate
											 options:0];

		// Find a EventGroup for this startDate
		EventGroup *eventGroup = [self eventGroupAtDate:startDate];

		// Check if this eventGroup already has this event
		if (![eventGroup containsEvent:event]) {
			EventGroupChange *eventGroupChange = [EventGroupChange new];

			if (eventGroup) {	
				eventGroupChange.type = EventGroupChangeUpdate;
			} else {
				eventGroup = [[EventGroup alloc] initWithDate:startDate];
				[self.eventGroups addObject:eventGroup];

				eventGroupChange.type = EventGroupChangeInsert;
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
		NSDate *endOfDay = [startDate endOfDay];
		NSDateComponents *deltaSecondsComponent = [calender components:unitFlags
															  fromDate:startDate
																toDate:endOfDay
															   options:0];
		deltaSecondsComponent.second += 1;

		totalSecondsComponent.second += deltaSecondsComponent.second;
		eventSecondsComponent.second -= deltaSecondsComponent.second;
	}

	[self.eventGroups sortUsingSelector:@selector(reverseCompare:)];

	// Update the index for the changes
	for (EventGroupChange *eventGroupChange in changes) {
		NSUInteger i = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
			return [[(EventGroup *) obj GUID] isEqualToString:eventGroupChange.GUID];
		}];

		eventGroupChange.index = i;
	}

	DLog(@"end self.eventGroups.count %d", self.eventGroups.count);

	return [changes copy];
}

- (NSArray *)removeEvent:(Event *)event withConditionIsInvalid:(BOOL)condition {
	NSMutableArray *changes = [NSMutableArray array];

	for (EventGroup *eventGroup in self.eventGroups) {
		BOOL process = [eventGroup containsEvent:event];

		// Check if condition is given and if so only remove event if it is invalid
		if (condition && [eventGroup canContainEvent:event]) {
			process = NO;
		}

		if (process) {
			EventGroupChange *eventGroupChange = [EventGroupChange new];
			eventGroupChange.GUID = eventGroup.GUID;
			eventGroupChange.type = EventGroupChangeUpdate;

			[changes addObject:eventGroupChange];

			[eventGroup removeEvent:event];
		}
	}

	[self.eventGroups sortUsingSelector:@selector(reverseCompare:)];

	// Update the index
	for (EventGroupChange *eventGroupChange in changes) {
		NSUInteger i = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
			return [[(EventGroup *) obj GUID] isEqualToString:eventGroupChange.GUID];
		}];

		eventGroupChange.index = i;
	}

	// Remove empty eventGroups, we do this step seperatly from
	// the index build since what we want is the index of the entry before the delete
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

	return [changes copy];
}

- (NSArray *)updateEvent:(Event *)event {
	NSMutableArray *changes = [NSMutableArray array];

	// Update the event in any groups that contains it and can contain it, later we remove it from invalid groups
	for (EventGroup *eventGroup in self.eventGroups) {
		if ([eventGroup containsEvent:event] && [eventGroup canContainEvent:event]) {
			EventGroupChange *eventGroupChange = [EventGroupChange new];
			eventGroupChange.GUID = eventGroup.GUID;
			eventGroupChange.type = EventGroupChangeUpdate;

			[changes addObject:eventGroupChange];

			[eventGroup updateEvent:event];
		}
	}

	[self.eventGroups sortUsingSelector:@selector(reverseCompare:)];

	// Update the index for the update changes
	for (EventGroupChange *eventGroupChange in changes) {
		NSUInteger i = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
			return [[(EventGroup *) obj GUID] isEqualToString:eventGroupChange.GUID];
		}];

		eventGroupChange.index = i;
	}

	// Remove this event from any groups that it no longer can be in
	NSArray *deleteChanges = [self removeEvent:event withConditionIsInvalid:YES];
	[changes addObjectsFromArray:deleteChanges];

	// Insert event into any groups that can contain it, possibly creating new groups for this
	NSArray *insertChanges = [self addEvent:event];
	[changes addObjectsFromArray:insertChanges];

	return [changes copy];
}

- (NSArray *)updateActiveEvent {
	for (EventGroup *eventGroup in self.eventGroups) {
		if ([eventGroup isActive]) {
			return [self updateEvent:[eventGroup activeEvent]];
		}
	}

	return [NSArray array];
}

- (NSUInteger)count {
	return self.eventGroups.count;
}

- (EventGroup *)eventGroupAtIndex:(NSUInteger)index {
	return [self.eventGroups objectAtIndex:index];
}

- (EventGroup *)eventGroupAtDate:(NSDate *)date {
	for (EventGroup *eventGroup in self.eventGroups) {
		if ([eventGroup canContainDate:date]) {
			return eventGroup;
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Private instance methods


@end