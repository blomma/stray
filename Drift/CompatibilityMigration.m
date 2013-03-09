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

#define STRAY_COMPATIBILITY_LEVEL_KEY @"StrayCompatibilityLevel"
#define STATE_COMPATIBILITY_LEVEL_KEY @"stateCompatibilityLevel"

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

- (void)migrateToCompatibilityLevel:(NSNumber *)toLevel lastCompatibilityLevel:(NSNumber *)lastLevel migrationBlock:(void (^)())migrationBlock {
	// toLevel > lastLevel && toLevel <= appCompatibilityLevel
    NSNumber *appCompatibilityLevel = [[[NSBundle mainBundle] infoDictionary] objectForKey:STRAY_COMPATIBILITY_LEVEL_KEY];

    if ([toLevel compare:lastLevel] == NSOrderedDescending && [toLevel compare:appCompatibilityLevel] != NSOrderedDescending) {
        migrationBlock();
    }
}

- (void)migrate {
    //==================================================================================//
    // Migrate CoreData
    //==================================================================================//
    [self migrateCoreData];

    //==================================================================================//
    // Migrate State
    //==================================================================================//
    [self migrateState];
}

- (NSNumber *)stateCompatibilityLevel {
    NSNumber *stateCompatibilityLevel = [SDCloudUserDefaults objectForKey:STATE_COMPATIBILITY_LEVEL_KEY];
    return stateCompatibilityLevel ? stateCompatibilityLevel : @0;
}

- (void)setStateCompatibilityLevel:(NSNumber *)level {
    [SDCloudUserDefaults setObject:level forKey:STATE_COMPATIBILITY_LEVEL_KEY];
    [SDCloudUserDefaults synchronize];
}

- (void)migrateState {
    [self migrateToCompatibilityLevel:@1 lastCompatibilityLevel:[self stateCompatibilityLevel] migrationBlock:^{
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

        [self setStateCompatibilityLevel:@1];
    }];
}

- (NSNumber *)coredataCompatibilityLevel {
	Compatibility *compatibility = [Compatibility MR_findFirst];
	return compatibility ? compatibility.level : @0;
}

- (void)setCoredataCompatibilityLevel:(NSNumber *)level {
    Compatibility *compatibility = [Compatibility MR_findFirst];
    if (!compatibility) {
        compatibility = [Compatibility MR_createEntity];
    }

    compatibility.level = level;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (void)migrateCoreData {
    [self migrateToCompatibilityLevel:@1 lastCompatibilityLevel:[self coredataCompatibilityLevel] migrationBlock:^{
        NSArray *events = [Event MR_findAll];
        [events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setGuid:[[NSProcessInfo processInfo] globallyUniqueString]];
        }];

        NSArray *tags = [Tag MR_findAll];
        [tags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj setGuid:[[NSProcessInfo processInfo] globallyUniqueString]];
        }];

        [self setCoredataCompatibilityLevel:@1];
    }];
}

@end
