//
//  EventGroupsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroup.h"
#import "EventGroupChange.h"
#import "EventGroups.h"
#import "EventGroupsTableViewController.h"
#import "EventGroupsTableViewDataSource.h"
#import "EventGroupViewController.h"
#import "NSManagedObject+ActiveRecord.h"
#import "Tag.h"

@interface EventGroupsTableViewController ()

@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) EventGroupViewController *eventGroupViewController;
@property (nonatomic) EventGroupsTableViewDataSource *dataSource;

@end

@implementation EventGroupsTableViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    EventGroupsTableViewDataSource *dataSource = [EventGroupsTableViewDataSource new];

    self.dataSource = dataSource;
    self.tableView.dataSource = dataSource;

    self.eventGroupViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EventGroupViewController"];

	// Get starting list
    Tag *tag = [Tag where:@{ @"name" : @"Work" }].first;

	NSArray *events = [Event all];
	self.dataSource.eventGroups = [[EventGroups alloc] initWithEvents:events filter:tag];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:NSManagedObjectContextDidSaveNotification
	                                           object:[[CoreDataManager instance] managedObjectContext]];

	[self.dataSource.eventGroups addObserver:self
                                  forKeyPath:@"existsActiveEventGroup"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];

	// Do an inital check to see if there is an active event group
	if (self.dataSource.eventGroups.activeEventGroup) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
															target:self
														  selector:@selector(timerUpdate)
														  userInfo:nil
														   repeats:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateActiveEventGroup];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [sender setSelected:NO animated:YES];

    EventGroupViewController *eventGroupViewController = [segue destinationViewController];

    EventGroup *eventGroup = [self.dataSource.eventGroups eventGroupAtIndex:(NSUInteger)[self.tableView indexPathForSelectedRow].row];

    eventGroupViewController.eventGroup = eventGroup;
}

#pragma mark -
#pragma mark UITableViewDelegate

#pragma mark -
#pragma mark Private methods

- (void)dataModelDidSave:(NSNotification *)note {
    EventGroups *eventGroups = self.dataSource.eventGroups;
    NSMutableArray *changes = [NSMutableArray array];

    // Inserted Events
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSArray *insertedEvents = [[insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }] allObjects];

    DLog(@"insertedObjects %@", insertedObjects);
    DLog(@"insertedEvents %@", insertedEvents);

    for (Event *event in insertedEvents) {
        NSArray *addChanges = [eventGroups addEvent:event];
        [changes addObjectsFromArray:addChanges];
    }

    // Deleted Events
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSArray *deletedEvents = [[deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }] allObjects];

    DLog(@"deletedObjects %@", deletedObjects);
    DLog(@"deletedEvents %@", deletedEvents);

    for (Event *event in deletedEvents) {
        NSArray *deleteChanges = [eventGroups removeEvent:event];
        [changes addObjectsFromArray:deleteChanges];
    }

    // Updated Events
    // this can generate update, insert and delete changes
    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
    NSArray *updatedEvents = [[updatedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }] allObjects];

    DLog(@"updatedObjects %@", updatedObjects);
    DLog(@"updatedEvents %@", updatedEvents);

    for (Event *event in updatedEvents) {
        NSArray *updateChanges = [eventGroups updateEvent:event];
        [changes addObjectsFromArray:updateChanges];
    }

    [self updateTableViewWithChanges:changes];
}

- (void)updateTableViewWithChanges:(NSArray *)changes {
    if (changes.count > 0) {
        NSMutableArray *insertIndexPaths = [NSMutableArray array];
        NSMutableArray *deleteIndexPaths = [NSMutableArray array];
        NSMutableArray *updateIndexPaths = [NSMutableArray array];

        for (EventGroupChange *eventGroupChange in changes) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0];
            if ([eventGroupChange.type isEqualToString:EventGroupChangeUpdate]) {
                [updateIndexPaths addObject:path];
            } else if ([eventGroupChange.type isEqualToString:EventGroupChangeDelete]) {
                [deleteIndexPaths addObject:path];
            } else if ([eventGroupChange.type isEqualToString:EventGroupChangeInsert]) {
                [insertIndexPaths addObject:path];
            }
        }

        [self.tableView beginUpdates];

        if (insertIndexPaths.count > 0) {
            DLog(@"insertIndexPaths %@", insertIndexPaths);
            [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
        }

        if (deleteIndexPaths.count > 0) {
            DLog(@"deleteIndexPaths %@", deleteIndexPaths);
            [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        }

        [self.tableView endUpdates];

        if (updateIndexPaths.count > 0) {
            DLog(@"updateIndexPaths %@", updateIndexPaths);
            [self.dataSource tableView:self.tableView refreshRowsAtIndexPaths:updateIndexPaths];
        }
    }
}

- (void)timerUpdate {
	[self updateActiveEventGroup];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"existsActiveEventGroup"]) {
		BOOL existsActiveEventGroup = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		if (existsActiveEventGroup) {
			if (!self.updateTimer.isValid) {
				self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
																	target:self
																  selector:@selector(timerUpdate)
																  userInfo:nil
																   repeats:YES];
			}
		} else {
			[self.updateTimer invalidate];
		}
	}
}

- (void)updateActiveEventGroup {
    EventGroup *activeEventGroup = self.dataSource.eventGroups.activeEventGroup;
    if (!activeEventGroup) {
        return;
    }

    Event *event = [activeEventGroup activeEvent];

	NSArray *changes = [self.dataSource.eventGroups updateEvent:event];

    [self updateTableViewWithChanges:changes];
}

@end
