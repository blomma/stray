//
//  NSDate+Utilities.m
//  Drift
//
//  Created by Mikael Hultgren on 8/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NSDate+Utilities.h"

@implementation NSDate (Utilities)

static NSMutableDictionary *__calendars = nil;

+ (NSString *)threadIdentifier {
    return [NSString stringWithFormat:@"%p", (void *) [NSThread currentThread]];
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

@end
