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

    self.dataSource = [[EventGroupsTableViewDataSource alloc] init];
    self.tableView.dataSource = self.dataSource;

    self.eventGroupViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EventGroupViewController"];

	// Get starting list
	NSArray *events = [Event all];
	self.dataSource.eventGroups = [[EventGroups alloc] initWithEvents:events];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(handleDataModelChange:)
	                                             name:NSManagedObjectContextDidSaveNotification
	                                           object:[[CoreDataManager instance] managedObjectContext]];

	[self.dataSource.eventGroups addObserver:self
                                  forKeyPath:@"existsActiveEventGroup"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];

	// Do an inital check to see if there is an active event group
	if (self.dataSource.eventGroups.existsActiveEventGroup) {
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

- (void)handleDataModelChange:(NSNotification *)note {
    EventGroups *eventGroups = self.dataSource.eventGroups;
    NSMutableArray *changes = [NSMutableArray array];

    // Inserted Events
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    if (insertedObjects) {
        NSArray *insertedEvents = [insertedObjects allObjects];

        for (Event *event in insertedEvents) {
            NSArray *addChanges = [eventGroups addEvent:event];
            [changes addObjectsFromArray:addChanges];
        }
    }

    // Deleted Events
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    if (deletedObjects) {
        NSArray *deletedEvents = [deletedObjects allObjects];

        for (Event *event in deletedEvents) {
            NSArray *deleteChanges = [eventGroups removeEvent:event withConditionIsInvalid:NO];
            [changes addObjectsFromArray:deleteChanges];
        }
    }

    // Updated Events
    // this can generate update, insert and delete changes
    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
    if (updatedObjects) {
        NSArray *updatedEvents = [updatedObjects allObjects];

        for (Event *event in updatedEvents) {
            NSArray *updateChanges = [eventGroups updateEvent:event withConditionIsActive:NO];
            [changes addObjectsFromArray:updateChanges];
        }
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

        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];

        [self.tableView endUpdates];

        [self.dataSource tableView:self.tableView refreshRowsAtIndexPaths:updateIndexPaths];
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
    EventGroups *eventGroups = self.dataSource.eventGroups;

    NSUInteger index = [eventGroups indexForActiveEventGroup];
    if (index == NSNotFound) {
        return;
    }

    Event *event = [[eventGroups eventGroupAtIndex:index] activeEvent];

	NSArray *changes = [eventGroups updateEvent:event withConditionIsActive:YES];

    [self updateTableViewWithChanges:changes];
}

@end
