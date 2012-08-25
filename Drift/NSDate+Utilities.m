//
//  NSDate+Utilities.m
//  Drift
//
//  Created by Mikael Hultgren on 8/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NSDate+Utilities.h"

@implementation NSDate (Utilities)

- (NSDate *)beginningOfDayWithCalendar:(NSCalendar *)calendar {
    // Get the weekday component of the current date
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
																   fromDate:self];
	return [calendar dateFromComponents:components];
}

- (NSDate *)endOfDayWithCalendar:(NSCalendar *)calendar {
	NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	// to get the end of day for a particular date, add 1 day
	[componentsToAdd setDay:1];

	NSDate *endOfDay = [calendar dateByAddingComponents:componentsToAdd
                                                 toDate:[self beginningOfDayWithCalendar:calendar]
                                                options:0];

	return endOfDay;
}

- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate {
	return (([self compare:beginDate] != NSOrderedAscending) && ([self compare:endDate] != NSOrderedDescending));
}

- (BOOL)isEqualToDateIgnoringTime:(NSDate *)date withCalendar:(NSCalendar *)calendar {
    static NSUInteger units = (NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit |  NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit);
    
	NSDateComponents *components1 = [calendar components:units fromDate:self];
	NSDateComponents *components2 = [calendar components:units fromDate:date];

	return ((components1.year  == components2.year) &&
			(components1.month == components2.month) &&
			(components1.day   == components2.day));
}

@end