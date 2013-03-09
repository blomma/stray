//
//  CompatibilityMigration.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-03-09.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "CompatibilityMigration.h"

#import "Compatibility.h"
#import "Event.h"
#import "Tag.h"
#import "SDCloudUserDefaults.h"

@implementation CompatibilityMigration

- (id)init {
	self = [super init];
	if (self) {
	}

	return self;
}

#pragma mark -
#pragma mark Class methods

+ (CompatibilityMigration *)instance {
	static CompatibilityMigration *sharedCompatibilityMigration = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        sharedCompatibilityMigration = [[self alloc] init];
    });

	return sharedCompatibilityMigration;
}

- (void)migrate {
	NSNumber *compatibilityLevel = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"StrayCompatibilityLevel"];

    //==================================================================================//
    // Migrate CoreData
    //==================================================================================//
	Compatibility *compatibility        = [Compatibility MR_findFirst];
	NSNumber *coredataCompatibilityLevel = !compatibility ? [NSNumber numberWithInt:0] : compatibility.level;

	if (![coredataCompatibilityLevel isEqualToNumber:compatibilityLevel]) {
		[self migrateCoreDataFromCompatibilityLevel:coredataCompatibilityLevel toCompatibilityLevel:compatibilityLevel];
	}

    //==================================================================================//
    // Migrate State
    //==================================================================================//
    NSNumber *stateCompatibilityLevel = [SDCloudUserDefaults objectForKey:@"stateCompatibilityLevel"];
    if (!stateCompatibilityLevel) {
        stateCompatibilityLevel = [NSNumber numberWithInt:0];
    }

    if (![stateCompatibilityLevel isEqualToNumber:compatibilityLevel]) {
        [self migrateStateFromCompatibilityLevel:stateCompatibilityLevel toCompatibilityLevel:compatibilityLevel];
    }
}

- (void)migrateStateFromCompatibilityLevel:(NSNumber *)fromLevel toCompatibilityLevel:(NSNumber *)toLevel {
	for (NSUInteger i = (NSUInteger)[fromLevel longLongValue] + 1; i <= [toLevel longLongValue]; i++) {
		switch (i) {
            case 0:
                // Do Nothing, this is the base state
                break;

            case 1:
                [self stateUp_1];

            default:
                break;
		}
	}

    [SDCloudUserDefaults setObject:toLevel forKey:@"stateCompatibilityLevel"];
    [SDCloudUserDefaults synchronize];
}

- (void)stateUp_1 {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];

    //==================================================================================//
    // ACTIVE EVENT
    //==================================================================================//
    [SDCloudUserDefaults removeObjectForKey:@"activeEvent"];

    //==================================================================================//
    // SELECTED EVENT
    //==================================================================================//
    NSData *uriData = [SDCloudUserDefaults objectForKey:@"selectedEvent"];
    if (uriData) {
        NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
        NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
        if (objectID) {
            Event *event = (Event *)[context objectWithID:objectID];
            [SDCloudUserDefaults setString:event.guid forKey:@"selectedEventGUID"];
        }
    }

    [SDCloudUserDefaults removeObjectForKey:@"selectedEvent"];

    //==================================================================================//
    // EVENTSGROUPEDBYDATE FILTER
    //==================================================================================//
    NSArray *objects = [SDCloudUserDefaults objectForKey:@"eventGroupsFilter"];

    if (!objects) {
        objects = [SDCloudUserDefaults objectForKey:@"eventsGroupedByDateFilter"];
    }

    if (objects) {
        NSMutableSet *eventsGroupedByDateFilter = [NSMutableSet set];

        // Load them up
        for (uriData in objects) {
            NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
            NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
            if (objectID) {
                Tag *tag = (Tag *)[context objectWithID:objectID];
                [eventsGroupedByDateFilter addObject:tag.guid];
            }
        }

        // And resave them
        [SDCloudUserDefaults setObject:[eventsGroupedByDateFilter allObjects] forKey:@"eventGUIDSGroupedByDateFilter"];
    }

    [SDCloudUserDefaults removeObjectForKey:@"eventGroupsFilter"];
    [SDCloudUserDefaults removeObjectForKey:@"eventsGroupedByDateFilter"];


    //==================================================================================//
    // EVENTSGROUPEDBYSTARTDATE FILTER
    //==================================================================================//
    objects = [SDCloudUserDefaults objectForKey:@"eventsFilter"];

    if (!objects) {
        objects = [SDCloudUserDefaults objectForKey:@"eventsGroupedByStartDateFilter"];
    }

    if (objects) {
        NSMutableSet *eventsGroupedByStartDateFilter = [NSMutableSet set];

        // Load them up
        for (uriData in objects) {
            NSURL *uri                  = [NSKeyedUnarchiver unarchiveObjectWithData:uriData];
            NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:uri];
            if (objectID) {
                Tag *tag = (Tag *)[context objectWithID:objectID];
                [eventsGroupedByStartDateFilter addObject:tag.guid];
            }
        }

        // And resave them
        [SDCloudUserDefaults setObject:[eventsGroupedByStartDateFilter allObjects] forKey:@"eventGUIDSGroupedByStartDateFilter"];
    }

    [SDCloudUserDefaults removeObjectForKey:@"eventsFilter"];
    [SDCloudUserDefaults removeObjectForKey:@"eventsGroupedByStartDateFilter"];
}

- (void)migrateCoreDataFromCompatibilityLevel:(NSNumber *)fromLevel toCompatibilityLevel:(NSNumber *)toLevel {
	for (NSUInteger i = (NSUInteger)[fromLevel longLongValue] + 1; i <= [toLevel longLongValue]; i++) {
		switch (i) {
            case 0:
                // Do Nothing, this is the base state
                break;
                
            case 1:
                [self eventUp_1];
                [self tagUp_1];
                
            default:
                break;
		}
	}

	Compatibility *compatibility = [Compatibility MR_findFirst];
	if (!compatibility) {
		compatibility = [Compatibility MR_createEntity];
	}

	compatibility.level = toLevel;
	[[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (void)eventUp_1 {
	// We go thru every Event and add a guid to it
	NSArray *events = [Event MR_findAll];
	[events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setGuid:[[NSProcessInfo processInfo] globallyUniqueString]];
    }];
}

- (void)tagUp_1 {
	// We go thru every Tag and add a guid to it
	NSArray *tags = [Tag MR_findAll];
	[tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setGuid:[[NSProcessInfo processInfo] globallyUniqueString]];
    }];
}

@end
