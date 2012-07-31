//
//  EventGroups.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroups.h"
#import "EventGroup.h"

@interface EventGroups ()

@property (nonatomic) NSMutableArray *eventGroups;

@end

@implementation EventGroups

- (id)initWithEvents:(NSArray *)events {
	if ((self = [super init])) {
		self.eventGroups = [NSMutableArray array];
	}

	return self;
}

#pragma mark -
#pragma mark Public instance methods

- (void)addEvent:(Event *)event {
	NSDate *startDate = event.startDate;
	NSDate *stopDate = event.stopDate;

	// Is the event running, if so set the stopDate to now
	if (event.runningValue) {
		stopDate = [NSDate date];
	}

	// start of the day
	NSDate *startOfDay;
	[[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit startDate:&startOfDay interval:0 forDate:event.startDate];
}

#pragma mark -
#pragma mark Private instance methods

- (void)findGroupEventForDate:(NSDate *)date {

}

@end
