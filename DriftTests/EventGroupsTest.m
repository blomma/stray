//
//  DriftDateCalculation.m
//  Drift
//
//  Created by Mikael Hultgren on 8/17/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupsTest.h"
#import "../Drift/Event.h"
#import "../Drift/EventGroup.h"
#import "../Drift/EventGroups.h"
#import "../Drift/NSDate+Utilities.h"
#import "../MagicalRecord/CoreData+MagicalRecord.h"

@implementation EventGroupsTest

- (void)setUp; {
	[MagicalRecord setDefaultModelFromClass:[self class]];
	[MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void)tearDown; {
}

- (void)testAddEventsToEventGroups {
	NSDateComponents *hourComponents = [[NSDateComponents alloc] init];
	hourComponents.hour = 1;

	NSCalendar *calender = [NSCalendar currentCalendar];
	EventGroups *eventGroups = [[EventGroups alloc] init];

    NSDate *now = [self dateFromString:@"2012-05-06 12:00"];

	for (int i = 0; i < 5; i++) {
		Event *event = [Event MR_createEntity];
		[event setStartDate:[now copy]];
		[event setStopDate:[calender dateByAddingComponents:hourComponents
													 toDate:event.startDate
													options:0]];

		[eventGroups addEvent:event];
	}

	// There should be exactly 1 eventGroup
	STAssertTrue(eventGroups.count == 1, @"count");

	EventGroup *eventGroup = [eventGroups eventGroupAtDate:now];

	// Check groupDate
	STAssertTrue([[now beginningOfDay] isEqualToDate:eventGroup.groupDate], @"groupDate");

	// Check count, it should be 5
	STAssertTrue(eventGroup.count == 5, @"count");

	// We added a 5 events spanning 5 hours, lets see if that checks out
	STAssertTrue(eventGroup.timeActiveComponents.hour == 5, @"groupTime");
}

- (void)testAddEventToEventGroupsThatSpanMultipleDays {
	NSDateComponents *hourComponents = [[NSDateComponents alloc] init];
	hourComponents.hour = 24;

	NSCalendar *calender = [NSCalendar currentCalendar];
	EventGroups *eventGroups = [[EventGroups alloc] init];

    NSDate *now = [self dateFromString:@"2012-05-06 12:00"];

	Event *event = [Event MR_createEntity];
	[event setStartDate:[now copy]];
	[event setStopDate:[calender dateByAddingComponents:hourComponents
												 toDate:event.startDate
												options:0]];

	[eventGroups addEvent:event];

	STAssertTrue(eventGroups.count == 2, @"count");

	EventGroup *eventGroup = [eventGroups eventGroupAtDate:now];

	STAssertTrue(eventGroup.timeActiveComponents.hour == 12, @"groupTime");
}

- (void)testAddEventsToEventGroupsThatAreNotFollowingOnEachOthersHeels {
	NSDateComponents *hourComponents = [[NSDateComponents alloc] init];
	hourComponents.hour = 2;

	NSCalendar *calender = [NSCalendar currentCalendar];
	EventGroups *eventGroups = [[EventGroups alloc] init];

	// First date
    NSDate *now = [self dateFromString:@"2012-05-06 12:00"];

	Event *event = [Event MR_createEntity];
	[event setStartDate:[now copy]];
	[event setStopDate:[calender dateByAddingComponents:hourComponents
												 toDate:event.startDate
												options:0]];

	[eventGroups addEvent:event];

	// second date
    now = [self dateFromString:@"2012-05-06 16:00"];

	event = [Event MR_createEntity];
	[event setStartDate:[now copy]];
	[event setStopDate:[calender dateByAddingComponents:hourComponents
												 toDate:event.startDate
												options:0]];

	[eventGroups addEvent:event];



	STAssertTrue(eventGroups.count == 1, @"count");

	EventGroup *eventGroup = [eventGroups eventGroupAtDate:now];

	STAssertTrue(eventGroup.timeActiveComponents.hour == 4, @"groupTime");
}

- (NSDate *)dateFromString:(NSString *)date {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];

    return [dateFormatter dateFromString:date];
}

@end
