//
//  EventDataManager.m
//  Drift
//
//  Created by Mikael Hultgren on 7/25/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventDataManager.h"

@implementation EventDataManager

#pragma mark -
#pragma mark Lifecycle

- (id)init {
	if (self = [super init]) {
	}

	return self;
}

#pragma mark -
#pragma mark Class methods

+ (id)sharedManager {
	static EventDataManager *sharedEventDataManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedEventDataManager = [[self alloc] init];
	});
	return sharedEventDataManager;
}

#pragma mark -
#pragma mark Public methods

- (void)persistCurrentEvent {
	[[NSManagedObjectContext MR_defaultContext] MR_save];
}

- (Event *)createEvent {
	return [Event MR_createEntity];
}

- (void)deleteEvent:(Event *)event {
    [event MR_deleteEntity];
}

- (Event *)latestEvent {
	if ([Event MR_countOfEntities] > 0) {
		NSArray *eventArray = [Event MR_findAllSortedBy:@"startDate" ascending:NO];
		return [eventArray objectAtIndex:0];
	}

    return nil;
}

#pragma mark -
#pragma mark Private methods

@end