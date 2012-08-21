//
//  NSDate+Utilities.m
//  Drift
//
//  Created by Mikael Hultgren on 8/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NSDate+Utilities.h"

static NSUInteger DATE_COMPONENTS = (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit);

@implementation NSDate (Utilities)

- (NSDate *)beginningOfDay {
    // Get the weekday component of the current date
	NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
											   fromDate:self];
	return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (NSDate *)endOfDay {
	NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	// to get the end of day for a particular date, add 1 day
	[componentsToAdd setDay:1];

	NSDate *endOfDay = [[NSCalendar currentCalendar] dateByAddingComponents:componentsToAdd
												 toDate:[self beginningOfDay]
												options:0];

	return endOfDay;
}

- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate {
	return (([self compare:beginDate] != NSOrderedAscending) && ([self compare:endDate] != NSOrderedDescending));
}

- (BOOL)isEqualToDateIgnoringTime:(NSDate *)date {
	NSDateComponents *components1 = [[NSCalendar currentCalendar] components:DATE_COMPONENTS fromDate:self];
	NSDateComponents *components2 = [[NSCalendar currentCalendar] components:DATE_COMPONENTS fromDate:date];

	return ((components1.year  == components2.year) &&
			(components1.month == components2.month) &&
			(components1.day   == components2.day));
}

@end