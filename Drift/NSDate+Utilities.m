//
//  NSDate+Utilities.m
//  Drift
//
//  Created by Mikael Hultgren on 8/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NSDate+Utilities.h"

@implementation NSDate (Utilities)

static NSMutableDictionary * __calendars = nil;
static NSMutableDictionary *__dateFormatters = nil;

+ (NSString *)threadIdentifier {
	return [NSString stringWithFormat:@"%p", (void *)[NSThread currentThread]];
}

+ (NSCalendar *)calendar {
	if (!__calendars)
		__calendars = [[NSMutableDictionary alloc] initWithCapacity:0];

	NSString *keyName = [NSDate threadIdentifier];
	NSCalendar *calendar = __calendars[keyName];

	if (!calendar) {
		calendar = [NSCalendar autoupdatingCurrentCalendar];

		__calendars[keyName] = calendar;
	}

	return calendar;
}

+ (NSDateFormatter *)dateFormatter {
	if (!__dateFormatters)
		__dateFormatters = [[NSMutableDictionary alloc] initWithCapacity:0];

	NSString *keyName = [NSDate threadIdentifier];
	NSDateFormatter *dateFormatter = __dateFormatters[keyName];

	if (!dateFormatter) {
		dateFormatter = [[NSDateFormatter alloc] init];

		__dateFormatters[keyName] = dateFormatter;
	}

	return dateFormatter;
}

- (NSDate *)startOfCurrentDay {
	static NSUInteger units = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
	// Get the weekday component of the current date

	NSDateComponents *components = [[NSDate calendar] components:units
	                                                    fromDate:self];

	components.hour   = 0;
	components.minute = 0;
	components.second = 0;

	return [[NSDate calendar] dateFromComponents:components];
}

- (NSDate *)endOfCurrentDay {
	NSDateComponents *components = [[NSDateComponents alloc] init];
	// to get the end of day for a particular date, add 1 day
	components.day = 1;

	NSDate *endOfDay = [[NSDate calendar] dateByAddingComponents:components
	                                                      toDate:[self startOfCurrentDay]
	                                                     options:0];

	return endOfDay;
}

- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate {
	return (([self compare:beginDate] != NSOrderedAscending) && ([self compare:endDate] != NSOrderedDescending));
}

- (NSString *)stringByFormat:(NSString *)format {
	NSDateFormatter *formatter = [NSDate dateFormatter];
	[formatter setDateFormat:format];
	return [formatter stringFromDate:self];
}

- (NSString *)stringByLongDateTimeFormat {
	NSDateFormatter *formatter = [NSDate dateFormatter];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	[formatter setTimeStyle:NSDateFormatterFullStyle];
	return [formatter stringFromDate:self];
}

- (NSString *)stringByLongDateFormat {
	NSDateFormatter *formatter = [NSDate dateFormatter];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	return [formatter stringFromDate:self];
}

- (NSString *)stringByLongTimeFormat {
	NSDateFormatter *formatter = [NSDate dateFormatter];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	[formatter setTimeStyle:NSDateFormatterFullStyle];
	return [formatter stringFromDate:self];
}

- (NSString *)stringByShortDateFormat {
	NSDateFormatter *formatter = [NSDate dateFormatter];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	return [formatter stringFromDate:self];
}

- (NSString *)stringByShortTimeFormat {
	NSDateFormatter *formatter = [NSDate dateFormatter];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	[formatter setTimeStyle:NSDateFormatterMediumStyle];
	return [formatter stringFromDate:self];
}

@end
