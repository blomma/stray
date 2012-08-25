//
//  EventGroup.m
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"
#import "NSDate+Utilities.h"

@interface EventGroup ()

@property (nonatomic, readwrite) NSMutableArray *events;
@property (nonatomic, readwrite) NSDate *groupDate;
@property (nonatomic, readwrite) NSString *GUID;
@property (nonatomic, readwrite) BOOL isActive;

@property (nonatomic) NSDateComponents *timeActiveComponentsCache;
@property (nonatomic) BOOL timeActiveComponentsCacheInvalid;

@property (nonatomic) NSCalendar *calendar;

@end

@implementation EventGroup

- (id)initWithDate:(NSDate *)date {
	if ((self = [super init])) {
        self.calendar  = [NSCalendar currentCalendar];

		self.groupDate = [date beginningOfDayWithCalendar:self.calendar];
		self.events    = [NSMutableArray array];
		self.GUID      = [[NSProcessInfo processInfo] globallyUniqueString];

		self.timeActiveComponentsCache = [[NSDateComponents alloc] init];
		self.timeActiveComponentsCache.hour   = 0;
		self.timeActiveComponentsCache.minute = 0;
		self.timeActiveComponentsCache.second = 0;
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSDateComponents *)timeActiveComponents {
	if (self.isActive || self.timeActiveComponentsCacheInvalid) {
		[self calculateTotalTimeRunning];
	}

	return self.timeActiveComponentsCache;
}

#pragma mark -
#pragma mark Public instance methods

- (BOOL)canContainDate:(NSDate *)date {
	return [date isEqualToDateIgnoringTime:self.groupDate withCalendar:self.calendar];
}

- (BOOL)isValidForEvent:(Event *)event {
	NSDate *stopDate = event.stopDate;

	if (event.isActiveValue) {
		stopDate = [NSDate date];
	}

	NSDate *startDate = [event.startDate beginningOfDayWithCalendar:self.calendar];

	return [self.groupDate isBetweenDate:startDate andDate:stopDate];
}

- (BOOL)containsEvent:(Event *)event {
	return [self.events containsObject:event];;
}

- (void)addEvent:(Event *)event {
	[self.events addObject:event];

	self.isActive = [self containsActiveEvent];

	self.timeActiveComponentsCacheInvalid = YES;
}

- (void)removeEvent:(Event *)event {
	[self.events removeObject:event];

	self.isActive = [self containsActiveEvent];

	self.timeActiveComponentsCacheInvalid = YES;
}

- (void)updateEvent:(Event *)event {
	self.isActive = [self containsActiveEvent];

	self.timeActiveComponentsCacheInvalid = YES;
}

- (Event *)activeEvent {
	for (Event *event in self.events) {
		if (event.isActiveValue) {
			return event;
		}
	}

	return nil;
}

- (NSUInteger)count {
	return [self.events count];
}

- (NSComparisonResult)reverseCompare:(id)element {
	return [[element groupDate] compare:[self groupDate]];
}

- (NSComparisonResult)compare:(id)element {
	return [[self groupDate] compare:[element groupDate]];
}

#pragma mark -
#pragma mark Private instance methods

- (BOOL)containsActiveEvent {
	NSDate *stopDate = self.groupDate;
	NSDate *toDay = [NSDate date];

	BOOL isActive = NO;

	for (Event *event in self.events){
		if (event.isActiveValue) {
			isActive = YES;
			stopDate = [stopDate laterDate:toDay];
		} else {
			stopDate = [stopDate laterDate:event.stopDate];
		}
	}

	// If endOfDay is later than calculated stopDate
	// and groupDate is today
	// and we found an event that is active
	if ([[self.groupDate endOfDayWithCalendar:self.calendar] laterDate:stopDate] &&
        [self.groupDate isEqualToDateIgnoringTime:toDay withCalendar:self.calendar] &&
        isActive) {
		return YES;
	} else {
		return NO;
	}
}

- (void)calculateTotalTimeRunning {
	static NSUInteger DATE_COMPONENTS = (NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);

	NSDate *endOfDay = [self.groupDate endOfDayWithCalendar:self.calendar];

	NSDate *deltaStart = [self.groupDate copy];
	NSDate *deltaEnd   = [self.groupDate copy];

	for (Event *event in self.events) {
		NSDate *startDate = [event.startDate laterDate:self.groupDate];
		NSDate *stopDate = event.stopDate;
		if (event.isActiveValue) {
			stopDate = [NSDate date];
		}
		stopDate = [stopDate earlierDate:endOfDay];

		NSDateComponents *components = [self.calendar components:DATE_COMPONENTS
                                                        fromDate:startDate
                                                          toDate:stopDate
                                                         options:0];

		deltaEnd = [self.calendar dateByAddingComponents:components
                                                  toDate:deltaEnd
                                                 options:0];
	}

	self.timeActiveComponentsCache	= [self.calendar components:DATE_COMPONENTS
                                                      fromDate:deltaStart
                                                        toDate:deltaEnd
                                                       options:0];

	self.timeActiveComponentsCacheInvalid = NO;
}

@end