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
@property (nonatomic, readwrite) BOOL isRunning;
@property (nonatomic) NSDateComponents *totalTimeRunningComponents;
@property (nonatomic) BOOL totalTimeRunningComponentsNeedsRecalculation;

@end

@implementation EventGroup

- (id)initWithDate:(NSDate *)groupDate {
	if ((self = [super init])) {
		self.groupDate = [groupDate beginningOfDay];
		self.events    = [NSMutableArray array];
		self.GUID      = [[NSProcessInfo processInfo] globallyUniqueString];

		self.totalTimeRunningComponents = [[NSDateComponents alloc] init];
		self.totalTimeRunningComponents.hour   = 0;
		self.totalTimeRunningComponents.minute = 0;
		self.totalTimeRunningComponents.second = 0;
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSDateComponents *)groupTime {
	if (self.isRunning || self.totalTimeRunningComponentsNeedsRecalculation) {
		[self calculateTotalTimeRunning];
	}

	return self.totalTimeRunningComponents;
}

#pragma mark -
#pragma mark Public instance methods

- (BOOL)canContainDate:(NSDate *)date {
	NSDate *beginningOfDay = [date beginningOfDay];
	return [beginningOfDay isEqualToDate:self.groupDate];
}

- (BOOL)canContainEvent:(Event *)event {
	NSDate *stopDate = event.stopDate;

	if (event.runningValue) {
		stopDate = [NSDate date];
	}

	return [self.groupDate isBetweenDate:event.startDate andDate:stopDate];
}

- (BOOL)containsEvent:(Event *)event {
	return [self.events containsObject:event];
}

- (void)addEvent:(Event *)event {
	if ([self.events containsObject:event]) {
		return;
	}

	[self.events addObject:event];

	// Is this running
	self.isRunning = [self containsRunningEvent];

	[self.events sortUsingSelector:@selector(compare:)];

	self.totalTimeRunningComponentsNeedsRecalculation = YES;
}

- (void)removeEvent:(Event *)event {
	if (![self.events containsObject:event]) {
		return;
	}

	[self.events removeObject:event];

	// Is this running
	self.isRunning = [self containsRunningEvent];

	[self.events sortUsingSelector:@selector(compare:)];

	self.totalTimeRunningComponentsNeedsRecalculation = YES;
}

- (void)updateEvent:(Event *)event {
	// Is this running
	self.isRunning = [self containsRunningEvent];

	[self.events sortUsingSelector:@selector(compare:)];

	self.totalTimeRunningComponentsNeedsRecalculation = YES;
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

- (BOOL)containsRunningEvent {
	for (Event *event in self.events){
		if (event.runningValue) {
			return YES;
		}
	}

	return NO;
}

- (void)calculateTotalTimeRunning {
	unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSCalendar *calender = [NSCalendar currentCalendar];

	NSDate *endOfDay = [self.groupDate endOfDay];

	NSDate *deltaStart = [self.groupDate copy];
	NSDate *deltaEnd   = [self.groupDate copy];

	for (Event *event in self.events) {
		NSDate *startDate = [event.startDate laterDate:self.groupDate];
		NSDate *stopDate = event.stopDate;
		if (event.runningValue) {
			stopDate = [NSDate date];
		}
		stopDate = [stopDate earlierDate:endOfDay];

		NSDateComponents *components = [calender components:unitFlags
												   fromDate:startDate
													 toDate:stopDate
													options:0];

		deltaEnd = [calender dateByAddingComponents:components
											 toDate:deltaEnd
											options:0];
	}

	self.totalTimeRunningComponents	= [calender components:unitFlags
												  fromDate:deltaStart
													toDate:deltaEnd
												   options:0];

	self.totalTimeRunningComponentsNeedsRecalculation = NO;
}

@end