//
//  EventGroup.m
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"
#import "NSDate+Utilities.h"
#import "Change.h"

@interface EventGroup ()

@property (nonatomic, readwrite) NSMutableArray *events;
@property (nonatomic, readwrite) NSDate *groupDate;

@property (nonatomic, readwrite) NSDateComponents *timeActiveComponents;
@property (nonatomic) BOOL timeActiveComponentsIsInvalid;

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
        self.calendar  = [NSCalendar currentCalendar];

		self.groupDate = [date beginningOfDayWithCalendar:self.calendar];
		self.events    = [NSMutableArray array];

		self.timeActiveComponents = [[NSDateComponents alloc] init];
		self.timeActiveComponents.hour   = 0;
		self.timeActiveComponents.minute = 0;
		self.timeActiveComponents.second = 0;
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSDateComponents *)timeActiveComponents {
	if (self.activeEvent || self.timeActiveComponentsIsInvalid) {
		[self updateTimeActiveComponents];
	}

	return _timeActiveComponents;
}

- (Event *)activeEvent {
    if (self.activeEventIsInvalid) {
        [self updateActiveEvent];
    }

    return _activeEvent;
}

- (NSUInteger)count {
	return [self.events count];
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

- (NSSet *)addEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet setWithCapacity:1];

    if ([self.events containsObject:event]) {
        return changes;
    }

    NSUInteger index = [self insertionIndexForEvent:event];
	[self.events insertObject:event atIndex:index];

    self.activeEventIsInvalid = YES;
	self.timeActiveComponentsIsInvalid = YES;

    Change *change = [Change new];
    change.index = index;
    change.type = ChangeInsert;
    change.object = event;
    change.parentObject = self;

    [changes addObject:change];

    return changes;
}

- (NSSet *)removeEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet setWithCapacity:1];

    NSUInteger index = [self.events indexOfObject:event];

    if (index == NSNotFound) {
        return changes;
    }

    [self.events removeObjectAtIndex:index];

    self.activeEventIsInvalid = YES;
	self.timeActiveComponentsIsInvalid = YES;

    Change *change = [Change new];
    change.index = index;
    change.type = ChangeDelete;
    change.object = event;
    change.parentObject = self;

    [changes addObject:change];

    return changes;
}

- (NSSet *)updateEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet setWithCapacity:1];

    if (![self.events containsObject:event]) {
        return changes;
    }

    self.activeEventIsInvalid = YES;
	self.timeActiveComponentsIsInvalid = YES;

    Change *change = [Change new];
    change.index = [self.events indexOfObject:event];
    change.type = ChangeUpdate;
    change.object = event;
    change.parentObject = self;

    [changes addObject:change];

    return changes;
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

	for (Event *event in self.events) {
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

	self.timeActiveComponents = [self.calendar components:unitFlags
                                                 fromDate:deltaStart
                                                   toDate:deltaEnd
                                                  options:0];

	self.timeActiveComponentsIsInvalid = NO;
}

- (NSUInteger)insertionIndexForEvent:(Event *)event {
    NSUInteger index = [self.events indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        return [(Event *)obj compare:event] == NSOrderedDescending;
    }];

    if (index == NSNotFound) {
        index = self.events.count;
    }

    return index;
}

@end