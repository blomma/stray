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

    // EVENTGROUPS FILTER
    NSArray *objects = [defaults objectForKey:@"eventGroupsFilter"];
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

    // EVENTS FILTER
    objects           = [defaults objectForKey:@"eventsFilter"];
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

    // EVENTGROUPS FILTER
    NSMutableSet *objects = [NSMutableSet set];
    for (Tag *tag in self.eventGroupsFilter) {
        uri     = [tag.objectID URIRepresentation];
        uriData = [NSKeyedArchiver archivedDataWithRootObject:uri];

        [objects addObject:uriData];
    }
    [defaults setObject:[objects allObjects] forKey:@"eventGroupsFilter"];

    // EVENTS FILTER
    objects = [NSMutableSet set];
    for (Tag *tag in self.eventsFilter) {
        uri     = [tag.objectID URIRepresentation];
        uriData = [NSKeyedArchiver archivedDataWithRootObject:uri];

        [objects addObject:uriData];
    }
    [defaults setObject:[objects allObjects] forKey:@"eventsFilter"];
}

@end