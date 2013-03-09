//
//  State.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-15.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "State.h"
#import "Tag.h"
#import "SDCloudUserDefaults.h"

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
    NSString *selectedEventGUID = [SDCloudUserDefaults stringForKey:@"selectedEventGUID"];
    if (selectedEventGUID) {
        self.selectedEvent = [Event MR_findFirstByAttribute:@"guid" withValue:selectedEventGUID];
    }

    //==================================================================================//
    // EVENTSGROUPEDBYDATE FILTER
    //==================================================================================//
    NSArray *objects = [SDCloudUserDefaults objectForKey:@"eventGUIDSGroupedByDateFilter"];
    if (objects) {
        for (NSString *guid in objects) {
            [self.eventsGroupedByDateFilter addObject:guid];
        }
    }

    //==================================================================================//
    // EVENTSGROUPEDBYSTARTDATE FILTER
    //==================================================================================//
    objects = [SDCloudUserDefaults objectForKey:@"eventGUIDSGroupedByStartDateFilter"];
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
    [SDCloudUserDefaults setString:self.selectedEvent.guid forKey:@"selectedEventGUID"];

    //==================================================================================//
    // EVENTSGROUPEDBYDATE FILTER
    //==================================================================================//
    [SDCloudUserDefaults setObject:[self.eventsGroupedByDateFilter allObjects] forKey:@"eventGUIDSGroupedByDateFilter"];

    //==================================================================================//
    // EVENTSGROUPEDBYSTARTDATE FILTER
    //==================================================================================//
    [SDCloudUserDefaults setObject:[self.eventsGroupedByStartDateFilter allObjects] forKey:@"eventGUIDSGroupedByStartDateFilter"];
}

@end