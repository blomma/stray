//
//  NSDate+Utilities.h
//  Drift
//
//  Created by Mikael Hultgren on 8/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

@interface NSDate (Utilities)

+ (NSCalendar *)calendar;

- (NSDate *)startOfCurrentDay;
- (NSDate *)endOfCurrentDay;
- (BOOL)isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate;

- (NSString *)stringByFormat:(NSString *)format;
- (NSString *)stringByLongDateTimeFormat;
- (NSString *)stringByLongDateFormat;
- (NSString *)stringByLongTimeFormat;
- (NSString *)stringByShortDateFormat;
- (NSString *)stringByShortTimeFormat;

@end
