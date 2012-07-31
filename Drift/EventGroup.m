//
//  EventGroup.m
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"

@interface EventGroup ()

@property (nonatomic) NSMutableArray *events;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *stopDate;

@end

@implementation EventGroup

- (id)initWithStartDate:(NSDate *)startDate {
	if ((self = [super init])) {
		self.startDate = startDate;
		self.events    = [NSMutableArray array];

		[self calculateGroupDate];
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSArray *)groupEvents {
	return [self.events copy];
}

- (NSDateComponents *)groupRunningTime {
	[self calculateStopDate];

	unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	return [[NSCalendar currentCalendar] components:unitFlags
										   fromDate:self.startDate
											 toDate:self.stopDate
											options:0];
}

#pragma mark -
#pragma mark Public instance methods

- (void)addEvent:(Event *)event {
	[self.events addObject:event];

	[self.events sortUsingSelector:@selector(compare:)];
}

- (void)removeEvent:(Event *)event {
	[self.events removeObject:event];

	[self.events sortUsingSelector:@selector(compare:)];
}

- (NSComparisonResult)compare:(id)element
{
	NSComparisonResult res = [[self groupDate] compare: [element groupDate]];
	return res;
}

#pragma mark -
#pragma mark Private instance methods

- (void)calculateGroupDate {
	NSDate *startOfDay;
	[[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit startDate:&startOfDay interval:0 forDate:self.startDate];

	self.groupDate = startOfDay;
}

- (void)calculateStopDate {
	NSDate *toDate;

	// Find the latest stopDate
	for (Event *event in self.events) {
		NSDate *stopDate = event.stopDate;

		// Is the event still running
		// if so set the now as the stopDate
		if (event.runningValue) {
			stopDate = [NSDate date];
		}

		toDate = [event.stopDate laterDate:toDate];
	}

	// start of the day
	NSDate *startOfDay;
	[[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit startDate:&startOfDay interval:0 forDate:self.startDate];

	// end of the day
	NSDateComponents *oneDay = [[NSDateComponents alloc] init];
	[oneDay setDay:1];
	NSDate *endOfDay         = [[NSCalendar currentCalendar] dateByAddingComponents:oneDay
	                                                                         toDate:startOfDay
	                                                                        options:0];

	// Is endOfDay smaller than toDate, then we have a long runner and we cap at endOfDay
	self.stopDate = [toDate earlierDate:endOfDay];
}

@end