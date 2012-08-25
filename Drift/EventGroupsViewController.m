//
//  TimerArchiveViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroup.h"
#import "EventGroupChange.h"
#import "EventGroups.h"
#import "EventGroupsViewController.h"
#import "EventGroupsViewModel.h"

@interface EventGroupsViewController ()

@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) EventGroupsViewModel *model;

@end

@implementation EventGroupsViewController

#pragma mark -
#pragma mark private properties

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
        self.model = [[EventGroupsViewModel alloc] init];
	}

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self updateActiveEventGroup];
}

- (void)viewDidLoad {
	[super viewDidLoad];

    self.tableView.dataSource = self.model;

	// Get starting list
	NSArray *events = [Event MR_findAll];
	self.model.eventGroups = [[EventGroups alloc] initWithEvents:events];

	// Get notified of new things happening
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(handleDataModelChange:)
	                                             name:NSManagedObjectContextObjectsDidChangeNotification
	                                           object:[NSManagedObjectContext MR_defaultContext]];

	[self.model.eventGroups addObserver:self
                             forKeyPath:@"existsActiveEventGroup"
                                options:NSKeyValueObservingOptionNew
                                context:NULL];

	// Do an inital check to see if there is an active event group
	if (self.model.eventGroups.existsActiveEventGroup) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
															target:self
														  selector:@selector(timerUpdate)
														  userInfo:nil
														   repeats:YES];
	}
}

- (void)handleDataModelChange:(NSNotification *)note {
    EventGroups *eventGroups = self.model.eventGroups;
    NSMutableArray *changes = [NSMutableArray array];
    
	// Inserted Events
	NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
	NSMutableArray *insertedEvents = [NSMutableArray arrayWithArray:[insertedObjects allObjects]];

	for (Event *event in insertedEvents) {
		NSArray *addChanges = [eventGroups addEvent:event];
        [changes addObjectsFromArray:addChanges];
	}

	// Deleted Events
	NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
	NSMutableArray *deletedEvents = [NSMutableArray arrayWithArray:[deletedObjects allObjects]];

	for (Event *event in deletedEvents) {
		NSArray *deleteChanges = [eventGroups removeEvent:event withConditionIsInvalid:NO];
        [changes addObjectsFromArray:deleteChanges];
	}

	// Updated Events
    // this can generate update, insert and delete changes
	NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
	NSMutableArray *updatedEvents = [NSMutableArray arrayWithArray:[updatedObjects allObjects]];

	for (Event *event in updatedEvents) {
		NSArray *updateChanges = [eventGroups updateEvent:event withConditionIsActive:NO];
        [changes addObjectsFromArray:updateChanges];
	}

    [self updateTableViewWithChanges:changes];
}

#pragma mark -
#pragma mark Private methods

- (void)updateTableViewWithChanges:(NSArray *)changes {
    if (changes.count > 0) {
        NSMutableArray *insertIndexPaths = [NSMutableArray array];
        NSMutableArray *deleteIndexPaths = [NSMutableArray array];
        NSMutableArray *updateIndexPaths = [NSMutableArray array];

        for (EventGroupChange *eventGroupChange in changes) {
            if ([eventGroupChange.type isEqualToString:EventGroupChangeUpdate]) {
                [updateIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
            } else if ([eventGroupChange.type isEqualToString:EventGroupChangeDelete]) {
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
            } else if ([eventGroupChange.type isEqualToString:EventGroupChangeInsert]) {
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
            }
        }

        [self.tableView beginUpdates];

        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        
        [self.tableView endUpdates];
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
    EventGroups *eventGroups = self.model.eventGroups;

    NSUInteger index = [eventGroups indexForActiveGroupEvent];
    if (index == NSNotFound) {
        return;
    }

    Event *event = [[eventGroups eventGroupAtIndex:index] activeEvent];

	NSArray *changes = [eventGroups updateEvent:event withConditionIsActive:YES];

    [self updateTableViewWithChanges:changes];
}

@end
