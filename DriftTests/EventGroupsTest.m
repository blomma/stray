//
//  DriftDateCalculation.m
//  Drift
//
//  Created by Mikael Hultgren on 8/17/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "DriftDateCalculation.h"
#import "../Drift/Event.h"
#import "../Drift/EventGroup.h"
#import "../Drift/EventGroups.h"
#import "../Drift/NSDate+Utilities.h"

@implementation DriftDateCalculation

- (void)testEventGroupGroupDate {
	NSDate *now = [NSDate date];

	EventGroup *eventGroup = [[EventGroup alloc] initWithGroupDate:now];

	STAssertTrue([now beginningOfDay] isEqualToDate:eventGroup.groupDate, @"groupDate");
}

- (void)testAddEventToEventGroup {
	NSDateComponents *hourComponents = [[NSDateComponents alloc] init];
	hourComponents.hour = 1;

	NSDate *now = [NSDate date];
	NSCalendar *calender = [NSCalendar currentCalendar];

	EventGroup *eventGroup = [[EventGroup alloc] initWithGroupDate:now];

	Event *event = [[Event alloc] init];
	event.startDate = [now copy];
	event.stopDate = [calender dateByAddingComponents:hourComponents
											   toDate:event.startDate
											  options:0];
	[eventGroup addEvent:event];

	STAssertTrue(eventGroup.count == 1, @"count");

	// We added a event spanning 1 hour, lets see if that checks out
	STAssertTrue(eventGroup.groupTime.hour == 1, @"runningTimeComponents");
}

//- (void)testAddEvents {
//	NSDateComponents *hourComponents = [[NSDateComponents alloc] init];
//	hourComponents.hour = 1;
//
//	NSDate *now = [NSDate date];
//	NSCalendar *calender = [NSCalendar currentCalendar];
//
//	EventGroups *eventGroups = [[EventGroups alloc] init];
//
//	for (int i = 0; i < 5; i++) {
//		Event *event = [[Event alloc] init];
//		event.startDate = [now copy];
//		event.stopDate = [calender dateByAddingComponents:hourComponents
//												   toDate:event.startDate
//												  options:0];
//
//		[eventGroups addEvent:event];
//	}
//
//}

@end
