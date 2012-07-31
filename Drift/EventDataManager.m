//
//  ModelManager.m
//  Drift
//
//  Created by Mikael Hultgren on 7/25/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventDataManager.h"

@implementation EventDataManager

- (id)init {
	if (self = [super init]) {
		[self setupLatestEvent];
	}

	return self;
}

#pragma mark -
#pragma mark Singleton Methods

+ (id)sharedManager {
	static EventDataManager *sharedEventDataManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedEventDataManager = [[self alloc] init];
	});
	return sharedEventDataManager;
}

#pragma mark -
#pragma mark Public instance methods

- (void)persistCurrentEvent {
	[[NSManagedObjectContext MR_defaultContext] MR_save];
}

- (void)createEvent {
	self.currentEvent = [Event MR_createEntity];
}

#pragma mark -
#pragma mark Private instance methods

- (void)setupLatestEvent {
	if ([Event MR_countOfEntities] > 0) {
		NSArray *eventArray = [Event MR_findAllSortedBy:@"startDate" ascending:NO];
		self.currentEvent = [eventArray objectAtIndex:0];
	}
	//	NSArray *eventArray = [Event MR_findByAttribute:@"running" withValue:[NSNumber numberWithBool:TRUE]];
}

@end