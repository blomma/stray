//
//  State.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-15.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "State.h"
#import "Tag.h"

@implementation State

- (id)init {
    self = [super init];
    if (self) {
        [self loadState];
    }

    return self;
}

- (void)loadState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSManagedObjectContext *context = [[CoreDataManager instance] managedObjectContext];

    // ACTIVE EVENT
    NSData *uriData = [defaults objectForKey:@"activeEvent"];
    if (uriData) {
        NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
        NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
        if (objectID) {
            self.activeEvent = (Event *)[context objectWithID:objectID];
        }
    }

    // SELECTED EVENT
    uriData = [defaults objectForKey:@"selectedEvent"];
    if (uriData) {
        NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
        NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
        if (objectID) {
            self.selectedEvent = (Event *)[context objectWithID:objectID];
        }
    }

    // EVENTSGROUPEDBYDATE FILTER
    // Check for legacy and load that first
    NSArray *objects = nil;

    objects = [defaults objectForKey:@"eventGroupsFilter"];

    if (!objects) {
        objects = [defaults objectForKey:@"eventsGroupedByDateFilter"];
    }

    self.eventGroupsFilter = [NSMutableSet set];
    if (objects) {
        for (uriData in objects) {
            NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
            NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
            if (objectID) {
                Tag *tag = (Tag *)[context objectWithID:objectID];
                [self.eventGroupsFilter addObject:tag];
            }
        }
    }

    // EVENTSGROUPEDBYSTARTDATE FILTER
    // Check for legacy and load that first
    objects = [defaults objectForKey:@"eventsFilter"];

    if (!objects) {
        objects = [defaults objectForKey:@"eventsGroupedByStartDateFilter"];
    }

    self.eventsFilter = [NSMutableSet set];
    if (objects) {
        for (uriData in objects) {
            NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
            NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
            if (objectID) {
                Tag *tag = (Tag *)[context objectWithID:objectID];
                [self.eventsFilter addObject:tag];
            }
        }
    }
}

#pragma mark -
#pragma mark Public methods

- (void)persistState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // ACTIVE EVENT
    NSURL *uri      = [self.activeEvent.objectID URIRepresentation];
    NSData *uriData = [NSKeyedArchiver archivedDataWithRootObject:uri];

    [defaults setObject:uriData forKey:@"activeEvent"];

    // SELECTED EVENT
    uri     = [self.selectedEvent.objectID URIRepresentation];
    uriData = [NSKeyedArchiver archivedDataWithRootObject:uri];

    [defaults setObject:uriData forKey:@"selectedEvent"];

    // EVENTSGROUPEDBYDATE FILTER
    NSMutableSet *objects = [NSMutableSet set];
    for (Tag *tag in self.eventGroupsFilter) {
        uri     = [tag.objectID URIRepresentation];
        uriData = [NSKeyedArchiver archivedDataWithRootObject:uri];

        [objects addObject:uriData];
    }
    // Remove legacy default
    [defaults removeObjectForKey:@"eventGroupsFilter"];

    [defaults setObject:[objects allObjects] forKey:@"eventsGroupedByDateFilter"];

    // EVENTSGROUPEDBYSTARTDATE FILTER
    objects = [NSMutableSet set];
    for (Tag *tag in self.eventsFilter) {
        uri     = [tag.objectID URIRepresentation];
        uriData = [NSKeyedArchiver archivedDataWithRootObject:uri];

        [objects addObject:uriData];
    }
    // Remove legacy default
    [defaults removeObjectForKey:@"eventsFilter"];

    [defaults setObject:[objects allObjects] forKey:@"eventsGroupedByStartDateFilter"];
}

@end