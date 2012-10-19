//
//  EventGroup.m
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"
#import "NSDate+Utilities.h"
#import "Global.h"

@interface EventGroup ()

@property (nonatomic, readwrite) NSMutableSet *events;

@property (nonatomic) NSMutableSet *filteredEvents;
@property (nonatomic) BOOL filteredEventsIsInvalid;

@property (nonatomic, readwrite) NSDate *groupDate;

@property (nonatomic, readwrite) NSDateComponents *filteredEventsDateComponents;

@property (nonatomic, readwrite) Event *activeEvent;
@property (nonatomic) BOOL activeEventIsInvalid;

@property (nonatomic) NSCalendar *calendar;

@end

@implementation EventGroup

#pragma mark -
#pragma mark Lifecycle

- (id)init {
    return [self initWithDate:nil];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithDate:(NSDate *)date {
    self = [super init];
	if (self) {
        self.calendar = [Global instance].calendar;

		self.groupDate = [date beginningOfDayWithCalendar:self.calendar];

		self.events    = [NSMutableSet set];
		self.filteredEvents    = [NSMutableSet set];

		self.filteredEventsDateComponents = [[NSDateComponents alloc] init];
		self.filteredEventsDateComponents.hour   = 0;
		self.filteredEventsDateComponents.minute = 0;
		self.filteredEventsDateComponents.second = 0;
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSUInteger)count {
    return self.events.count;
}

- (NSDateComponents *)filteredEventsDateComponents {
	if (self.activeEvent || self.filteredEventsIsInvalid) {
		[self updateTimeActiveComponents];
	}

	return _filteredEventsDateComponents;
}

- (Event *)activeEvent {
    if (self.activeEventIsInvalid) {
        [self updateActiveEvent];
    }

    return _activeEvent;
}

- (void)setFilter:(Tag *)filter {
    if ([filter isEqual:_filter]) {
        return;
    }

    _filter = filter;
	self.filteredEventsIsInvalid = YES;
}

- (NSMutableSet *)filteredEvents {
    if (self.filteredEventsIsInvalid) {
        if (self.filter) {
            [_filteredEvents removeAllObjects];
            [_filteredEvents unionSet:[self.events filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"inTag == %@",
                                                                                           self.filter]]];
        } else {
            [_filteredEvents unionSet:self.events];
        }

        self.filteredEventsIsInvalid = NO;
    }

    return _filteredEvents;
}

#pragma mark -
#pragma mark Public methods

- (BOOL)isValidForEvent:(Event *)event {
	NSDate *stopDate = event.stopDate;

	if ([event isActive]) {
		stopDate = [NSDate date];
	}

	NSDate *startDate = [event.startDate beginningOfDayWithCalendar:self.calendar];

	return [self.groupDate isBetweenDate:startDate andDate:stopDate];
}

- (BOOL)containsEvent:(Event *)event {
	return [self.events containsObject:event];
}

- (void)addEvent:(Event *)event {
	[self.events addObject:event];

    self.activeEventIsInvalid = YES;
    if (!self.filter || [event.inTag isEqual:self.filter]) {
        self.filteredEventsIsInvalid = YES;
    }
}

- (void)removeEvent:(Event *)event {
    [self.events removeObject:event];

    self.activeEventIsInvalid = YES;
    if (!self.filter || [event.inTag isEqual:self.filter]) {
        self.filteredEventsIsInvalid = YES;
    }
}

- (void)updateEvent:(Event *)event {
    self.activeEventIsInvalid = YES;
    if (!self.filter || [event.inTag isEqual:self.filter]) {
        self.filteredEventsIsInvalid = YES;
    }
}

- (NSComparisonResult)compare:(id)element {
	return [[element groupDate] compare:[self groupDate]];
}

#pragma mark -
#pragma mark Private methods

- (void)updateActiveEvent {
    self.activeEvent = nil;

	for (Event *event in self.events) {
		if ([event isActive]) {
            self.activeEvent = event;
            return;
		}
	}
}

- (void)updateTimeActiveComponents {
	static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

	NSDate *endOfDay = [self.groupDate endOfDayWithCalendar:self.calendar];

	NSDate *deltaStart = [self.groupDate copy];
	NSDate *deltaEnd   = [self.groupDate copy];

	for (Event *event in self.filteredEvents) {
		NSDate *startDate = [event.startDate laterDate:self.groupDate];
		NSDate *stopDate = event.stopDate;
		if ([event isActive]) {
			stopDate = [NSDate date];
		}
		stopDate = [stopDate earlierDate:endOfDay];

		NSDateComponents *components = [self.calendar components:unitFlags
                                                        fromDate:startDate
                                                          toDate:stopDate
                                                         options:0];

		deltaEnd = [self.calendar dateByAddingComponents:components
                                                  toDate:deltaEnd
                                                 options:0];
	}

	self.filteredEventsDateComponents = [self.calendar components:unitFlags
                                                         fromDate:deltaStart
                                                           toDate:deltaEnd
                                                          options:0];
}

@end