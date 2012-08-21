//
//  NSDate+Utilities.m
//  Drift
//
//  Created by Mikael Hultgren on 8/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NSDate+Utilities.h"

#define DATE_COMPONENTS (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
#define CURRENT_CALENDAR [NSCalendar currentCalendar]

@implementation NSDate (Utilities)

- (NSDate *)beginningOfDay {
    // Get the weekday component of the current date
	NSDateComponents *components = [CURRENT_CALENDAR components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
											   fromDate:self];
	return [CURRENT_CALENDAR dateFromComponents:components];
}

- (NSDate *)endOfDay {
	NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	// to get the end of day for a particular date, add 1 day
	[componentsToAdd setDay:1];

	NSDate *endOfDay = [CURRENT_CALENDAR dateByAddingComponents:componentsToAdd
												 toDate:[self beginningOfDay]
												options:0];

	return endOfDay;
}

- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate {
	return (([self compare:beginDate] != NSOrderedAscending) && ([self compare:endDate] != NSOrderedDescending));
}

- (BOOL)isEqualToDateIgnoringTime:(NSDate *)date {
	NSDateComponents *components1 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:self];
	NSDateComponents *components2 = [CURRENT_CALENDAR components:DATE_COMPONENTS fromDate:date];

	return ((components1.year  == components2.year) &&
			(components1.month == components2.month) &&
			(components1.day   == components2.day));
}

@end