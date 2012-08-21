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

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *stopDate;

@property (nonatomic) NSString *GUID;
@property (nonatomic, readwrite) BOOL isActive;

@property (nonatomic) NSDateComponents *timeActiveComponentsCache;
@property (nonatomic) BOOL timeActiveComponentsCacheInvalid;

@end

@implementation EventGroup

- (id)initWithDate:(NSDate *)groupDate {
	if ((self = [super init])) {
		self.groupDate = [groupDate beginningOfDay];
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
	return [date isEqualToDateIgnoringTime:self.groupDate];
}

- (BOOL)canContainEvent:(Event *)event {
	NSDate *stopDate = event.stopDate;

	if (event.isActiveValue) {
		stopDate = [NSDate date];
	}

	NSDate *startDate = [event.startDate beginningOfDay];

	BOOL isBetween = [self.groupDate isBetweenDate:startDate andDate:stopDate];
	return isBetween;
}

- (BOOL)containsEvent:(Event *)event {
	BOOL contains = [self.events containsObject:event];;
	return contains;
}

- (void)addEvent:(Event *)event {
	if ([self.events containsObject:event]) {
		return;
	}

	[self.events addObject:event];

	self.isActive = [self containsActiveEvent];

	self.timeActiveComponentsCacheInvalid = YES;
}

- (void)removeEvent:(Event *)event {
	if (![self.events containsObject:event]) {
		return;
	}

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
	NSComparisonResult res = [[element groupDate] compare:[self groupDate]];

	return res;
}

- (NSComparisonResult)compare:(id)element {
	NSComparisonResult res = [[self groupDate] compare:[element groupDate]];

	return res;
}

#pragma mark -
#pragma mark Private instance methods

- (BOOL)containsActiveEvent {
	for (Event *event in self.events){
		if (event.isActiveValue) {
			return YES;
		}
	}

	return NO;
}

- (void)calculateTotalTimeRunning {
	static NSUInteger DATE_COMPONENTS = (NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);

	NSCalendar *calender = [NSCalendar currentCalendar];

	NSDate *endOfDay = [self.groupDate endOfDay];

	NSDate *deltaStart = [self.groupDate copy];
	NSDate *deltaEnd   = [self.groupDate copy];

	for (Event *event in self.events) {
		NSDate *startDate = [event.startDate laterDate:self.groupDate];
		NSDate *stopDate = event.stopDate;
		if (event.isActiveValue) {
			stopDate = [NSDate date];
		}
		stopDate = [stopDate earlierDate:endOfDay];

		NSDateComponents *components = [calender components:DATE_COMPONENTS
												   fromDate:startDate
													 toDate:stopDate
													options:0];

		deltaEnd = [calender dateByAddingComponents:components
											 toDate:deltaEnd
											options:0];
	}

	self.timeActiveComponentsCache	= [calender components:DATE_COMPONENTS
												 fromDate:deltaStart
												   toDate:deltaEnd
												  options:0];

	self.timeActiveComponentsCacheInvalid = NO;
}

@end