//
//  State.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-15.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "State.h"
#import "Tag.h"

@interface State ()

@property (nonatomic) NSMutableSet *eventsGroupedByDateFilter;
@property (nonatomic) NSMutableSet *eventsGroupedByStartDateFilter;

@end

@implementation State

- (id)init {
    self = [super init];
    if (self) {
        self.eventsGroupedByDateFilter = [NSMutableSet set];
        self.eventsGroupedByStartDateFilter = [NSMutableSet set];

        [self loadState];
    }

    return self;
}

#pragma mark -
#pragma mark Class methods

+ (State *)instance {
    static State *sharedState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            sharedState = [[self alloc] init];
        });

    return sharedState;
}

- (void)loadState {
    //==================================================================================//
    // SELECTED EVENT
    //==================================================================================//
    NSString *selectedEventGUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedEventGUID"];
    if (selectedEventGUID) {
        self.selectedEvent = [Event MR_findFirstByAttribute:@"guid" withValue:selectedEventGUID];
    }

    //==================================================================================//
    // EVENTSGROUPEDBYDATE FILTER
    //==================================================================================//
    NSArray *objects = [[NSUserDefaults standardUserDefaults] objectForKey:@"eventGUIDSGroupedByDateFilter"];
    if (objects) {
        for (NSString *guid in objects) {
            [self.eventsGroupedByDateFilter addObject:guid];
        }
    }

    //==================================================================================//
    // EVENTSGROUPEDBYSTARTDATE FILTER
    //==================================================================================//
    objects = [[NSUserDefaults standardUserDefaults] objectForKey:@"eventGUIDSGroupedByStartDateFilter"];
    if (objects) {
        for (NSString *guid in objects) {
            [self.eventsGroupedByStartDateFilter addObject:guid];
        }
    }
}

#pragma mark -
#pragma mark Public methods

- (void)persistState {
    //==================================================================================//
    // SELECTED EVENT
    //==================================================================================//
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedEvent.guid forKey:@"selectedEventGUID"];

    //==================================================================================//
    // EVENTSGROUPEDBYDATE FILTER
    //==================================================================================//
    [[NSUserDefaults standardUserDefaults] setObject:[self.eventsGroupedByDateFilter allObjects] forKey:@"eventGUIDSGroupedByDateFilter"];

    //==================================================================================//
    // EVENTSGROUPEDBYSTARTDATE FILTER
    //==================================================================================//
    [[NSUserDefaults standardUserDefaults] setObject:[self.eventsGroupedByStartDateFilter allObjects] forKey:@"eventGUIDSGroupedByStartDateFilter"];
}

@end