//
//  DataManager.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "DataManager.h"
#import "NSManagedObject+ActiveRecord.h"
#import "Change.h"
#import "Event.h"
#import "EventGroup.h"
#import "Tag.h"

NSString *const kDataManagerDidSaveNotification = @"kDataManagerDidSaveNotification";

NSString *const kEventChangesKey = @"kEventChangesKey";
NSString *const kEventGroupChangesKey = @"kEventGroupChangesKey";
NSString *const kTagChangesKey = @"kTagChangesKey";

@interface DataManager ()

@property (nonatomic) EventGroups *eventGroups;
@property (nonatomic) Tags *tags;
@property (nonatomic) State *state;

@end

@implementation DataManager

#pragma mark -
#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        self.eventGroups = [[EventGroups alloc] initWithEvents:[Event all] filter:nil];
        self.tags = [[Tags alloc] initWithTags:[Tag all]];
        self.state = [State where:@{ @"name" : @"default" }].first;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(dataModelDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:[[CoreDataManager instance] managedObjectContext]];
    }

    return self;
}

#pragma mark -
#pragma mark Public properties

- (State *)state {
    if (!_state) {
        _state = [State create];
        _state.name = @"default";

        [[CoreDataManager instance] saveContext];
    }

    return _state;
}

#pragma mark -
#pragma mark Class methods

+ (DataManager *)instance {
	static DataManager *sharedDataManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDataManager = [[self alloc] init];
	});

	return sharedDataManager;
}

#pragma mark -
#pragma mark Private methods

- (void)dataModelDidSave:(NSNotification *)note {
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

    DLog(@"insertedObjects %@", insertedObjects);
    DLog(@"deletedObjects %@", deletedObjects);
    DLog(@"updatedObjects %@", updatedObjects);

    // ==========
    // = Events =
    // ==========
    NSMutableSet *changes = [NSMutableSet set];

    // Updated Events
    // this can generate update, insert and delete changes
    NSArray *updatedEvents = [[updatedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }] allObjects];

    DLog(@"updatedEvents %@", updatedEvents);

    for (Event *event in updatedEvents) {
        [changes unionSet:[self.eventGroups updateEvent:event]];
    }
    
    // Inserted Events
    NSArray *insertedEvents = [[insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }] allObjects];

    DLog(@"insertedEvents %@", insertedEvents);

    for (Event *event in insertedEvents) {
        [changes unionSet:[self.eventGroups addEvent:event]];
    }

    // Deleted Events
    NSArray *deletedEvents = [[deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }] allObjects];

    DLog(@"deletedEvents %@", deletedEvents);

    for (Event *event in deletedEvents) {
        [changes unionSet:[self.eventGroups removeEvent:event]];
    }

    // ========
    // = Tags =
    // ========

    // Inserted Tags
    NSArray *insertedTags = [[insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }] allObjects];

    DLog(@"insertedTags %@", insertedTags);
    [changes unionSet:[self.tags addTags:insertedTags]];

    // Deleted tags
    NSArray *deletedTags = [[deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }] allObjects];

    DLog(@"deletedTags %@", deletedTags);
    [changes unionSet:[self.tags removeTags:deletedTags]];

    NSDictionary *userInfo = @{
    kEventChangesKey : [changes objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [(Change *)[obj object] isKindOfClass:[Event class]];
    }],
    kEventGroupChangesKey : [changes objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [(Change *)[obj object] isKindOfClass:[EventGroup class]];
    }],
    kTagChangesKey : [changes objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [(Change *)[obj object] isKindOfClass:[Tag class]];
    }]
    };

    [[NSNotificationCenter defaultCenter] postNotificationName:kDataManagerDidSaveNotification
                                                        object:self
                                                      userInfo:userInfo];
}

@end
