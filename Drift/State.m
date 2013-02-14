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

@implementation State

- (id)init {
    self = [super init];
    if (self) {
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
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    // SELECTED EVENT
    // Check for legacy and load that first
    NSData *uriData = [SDCloudUserDefaults objectForKey:@"selectedEvent"];
    if (uriData) {
        NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
        NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
        if (objectID) {
            self.selectedEvent = (Event *)[context objectWithID:objectID];
        }
    }

    // No legacy found, load the new key
    if (!uriData) {
        NSString *selectedEventGUID = [SDCloudUserDefaults stringForKey:@"selectedEventGUID"];
        if (selectedEventGUID) {
            self.selectedEvent = [Event MR_findFirstByAttribute:@"guid" withValue:selectedEventGUID];
        }
    }

    // EVENTSGROUPEDBYDATE FILTER
    // Check for legacy and load that first
    NSArray *objects = nil;

    objects = [SDCloudUserDefaults objectForKey:@"eventGroupsFilter"];

    self.eventsGroupedByDateFilter = [NSMutableSet set];
    if (!objects) {
        objects = [SDCloudUserDefaults objectForKey:@"eventsGroupedByDateFilter"];
        if (objects) {
            for (uriData in objects) {
                NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
                NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
                if (objectID) {
                    Tag *tag = (Tag *)[context objectWithID:objectID];
                    [self.eventsGroupedByDateFilter addObject:tag.guid];
                }
            }
        }
    }

    if (!objects) {
        objects = [SDCloudUserDefaults objectForKey:@"eventGUIDSGroupedByDateFilter"];
        if (objects) {
            for (NSString *guid in objects) {
                [self.eventsGroupedByDateFilter addObject:guid];
            }
        }
    }


    // EVENTSGROUPEDBYSTARTDATE FILTER
    // Check for legacy and load that first
    objects = [SDCloudUserDefaults objectForKey:@"eventsFilter"];

    self.eventsGroupedByStartDateFilter = [NSMutableSet set];
    if (!objects) {
        objects = [SDCloudUserDefaults objectForKey:@"eventsGroupedByStartDateFilter"];
        if (objects) {
            for (uriData in objects) {
                NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
                NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
                if (objectID) {
                    Tag *tag = (Tag *)[context objectWithID:objectID];
                    [self.eventsGroupedByStartDateFilter addObject:tag.guid];
                }
            }
        }
    }

    if (!objects) {
        objects = [SDCloudUserDefaults objectForKey:@"eventGUIDSGroupedByStartDateFilter"];
        if (objects) {
            for (NSString *guid in objects) {
                [self.eventsGroupedByStartDateFilter addObject:guid];
            }
        }
    }
}

#pragma mark -
#pragma mark Public methods

- (void)persistState {
    // ACTIVE EVENT

    // Remove legacy default
    [SDCloudUserDefaults removeObjectForKey:@"activeEvent"];

    // SELECTED EVENT

    // Remove legacy default
    [SDCloudUserDefaults removeObjectForKey:@"selectedEvent"];

    [SDCloudUserDefaults setString:self.selectedEvent.guid forKey:@"selectedEventGUID"];

    // EVENTSGROUPEDBYDATE FILTER
    NSMutableSet *objects = [NSMutableSet set];
    for (NSString *guid in self.eventsGroupedByDateFilter) {
        [objects addObject:guid];
    }

    // Remove legacy default
    [SDCloudUserDefaults removeObjectForKey:@"eventGroupsFilter"];
    [SDCloudUserDefaults removeObjectForKey:@"eventsGroupedByDateFilter"];

    [SDCloudUserDefaults setObject:[objects allObjects] forKey:@"eventGUIDSGroupedByDateFilter"];

    // EVENTSGROUPEDBYSTARTDATE FILTER
    objects = [NSMutableSet set];
    for (NSString *guid in self.eventsGroupedByStartDateFilter) {
        [objects addObject:guid];
    }

    // Remove legacy default
    [SDCloudUserDefaults removeObjectForKey:@"eventsFilter"];
    [SDCloudUserDefaults removeObjectForKey:@"eventsGroupedByStartDateFilter"];

    [SDCloudUserDefaults setObject:[objects allObjects] forKey:@"eventGUIDSGroupedByStartDateFilter"];
}

@end