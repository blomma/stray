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
@property (nonatomic) BOOL filteredEventsDateComponentsIsInvalid;

@property (nonatomic, readwrite) Event *activeEvent;
@property (nonatomic) BOOL activeEventIsInvalid;

@property (nonatomic) NSCalendar *calendar;

@end

@implementation EventGroup

- (id)init {
    return [self initWithGroupDate:nil];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithGroupDate:(NSDate *)groupDate {
    self = [super init];
	if (self) {
        self.calendar = [Global instance].calendar;

		self.groupDate = groupDate;

		self.events    = [NSMutableSet set];
		self.filteredEvents    = [NSMutableSet set];
        self.filteredEventsIsInvalid = YES;

		self.filteredEventsDateComponents = [[NSDateComponents alloc] init];
        self.filteredEventsDateComponentsIsInvalid = YES;
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSUInteger)count {
    return self.events.count;
}

- (NSDateComponents *)filteredEventsDateComponents {
	if (self.activeEvent || self.filteredEventsDateComponentsIsInvalid) {
		[self updateFilteredEventsDateComponents];
	}

	return _filteredEventsDateComponents;
}

- (Event *)activeEvent {
    if (self.activeEventIsInvalid) {
        [self updateActiveEvent];
    }

    return _activeEvent;
}

- (void)setFilters:(NSSet *)filters {
    _filters = filters;
	self.filteredEventsIsInvalid = YES;
}

- (NSMutableSet *)filteredEvents {
    if (self.filteredEventsIsInvalid) {
        if (self.filters.count == 0) {
            [_filteredEvents unionSet:self.events];
        } else {
            [_filteredEvents removeAllObjects];
            [_filteredEvents unionSet:[self.events filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"inTag in %@",
                                                                              self.filters]]];
        }

        self.filteredEventsIsInvalid = NO;
        self.filteredEventsDateComponentsIsInvalid = YES;
    }

    return _filteredEvents;
}

#pragma mark -
#pragma mark Public methods

- (BOOL)containsEvent:(Event *)event {
	return [self.events containsObject:event];
}

- (void)addEvent:(Event *)event {
	[self.events addObject:event];

    self.activeEventIsInvalid = YES;
    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.filteredEventsIsInvalid = YES;
    }
}

- (void)removeEvent:(Event *)event {
    [self.events removeObject:event];

    self.activeEventIsInvalid = YES;
    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.filteredEventsIsInvalid = YES;
    }
}

- (void)updateEvent:(Event *)event {
    self.activeEventIsInvalid = YES;
    if (self.filters.count == 0 || [self.filters containsObject:event.inTag]) {
        self.filteredEventsIsInvalid = YES;
    }
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

- (void)updateFilteredEventsDateComponents {
	static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

	NSDate *endOfDay = [self.groupDate endOfDayWithCalendar:self.calendar];

	NSDate *deltaStart = [self.groupDate copy];
	NSDate *deltaEnd   = [self.groupDate copy];

	for (Event *event in self.filteredEvents) {
		NSDate *startDate = [event.startDate laterDate:self.groupDate];
		NSDate *stopDate = [event isActive] ? [NSDate date] : event.stopDate;
		stopDate = [stopDate earlierDate:endOfDay];

		NSDateComponents *components = [self.calendar components:unitFlags
                                                        fromDate:startDate
                                                          toDate:stopDate
                                                         options:NSWrapCalendarComponents];

		deltaEnd = [self.calendar dateByAddingComponents:components
                                                  toDate:deltaEnd
                                                 options:0];
	}

	self.filteredEventsDateComponents = [self.calendar components:unitFlags
                                                         fromDate:deltaStart
                                                           toDate:deltaEnd
                                                          options:0];
    self.filteredEventsDateComponentsIsInvalid = NO;
}

@end