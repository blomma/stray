//
//  NSDate+Utilities.h
//  Drift
//
//  Created by Mikael Hultgren on 8/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#define D_MINUTE    60
#define D_HOUR      3600
#define D_DAY       86400
#define D_WEEK      604800
#define D_YEAR      31556926

@interface NSDate (Utilities)

- (NSDate *)beginningOfDayWithCalendar:(NSCalendar *)calendar;
- (NSDate *)endOfDayWithCalendar:(NSCalendar *)calendar;
- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate;
- (BOOL)isEqualToDateIgnoringTime:(NSDate *)date withCalendar:(NSCalendar *)calendar;

@end
