//
//  TimerArchiveViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventDataManager.h"
#import "EventGroup.h"
#import "EventGroupChange.h"
#import "EventGroupTableViewCell.h"
#import "EventGroups.h"
#import "EventGroupsViewController.h"

@interface EventGroupsViewController ()

@property (nonatomic, strong) EventGroups *eventGroups;
@property (nonatomic) NSTimer *updateTimer;

@end

@implementation EventGroupsViewController

#pragma mark -
#pragma mark private properties

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
	}

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self updateActiveEventGroup];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Get starting list
	NSArray *events = [Event MR_findAll];
	self.eventGroups = [[EventGroups alloc] initWithEvents:events];

	// Get notified of new things happening
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(handleDataModelChange:)
	                                             name:NSManagedObjectContextObjectsDidChangeNotification
	                                           object:[NSManagedObjectContext MR_defaultContext]];

	[self.eventGroups addObserver:self
					   forKeyPath:@"existsActiveEventGroup"
						  options:NSKeyValueObservingOptionNew
						  context:NULL];

	// Do an inital check to see if there is an active event group
	if (self.eventGroups.existsActiveEventGroup) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
															target:self
														  selector:@selector(timerUpdate)
														  userInfo:nil
														   repeats:YES];
	}
}

- (void)handleDataModelChange:(NSNotification *)note {
	NSMutableArray *insertIndexPaths = [NSMutableArray array];
	NSMutableArray *deleteIndexPaths = [NSMutableArray array];
	NSMutableArray *updateIndexPaths = [NSMutableArray array];

	// Inserted Events
	NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
	NSMutableArray *insertedEvents = [NSMutableArray arrayWithArray:[insertedObjects allObjects]];

	for (Event *event in insertedEvents) {
		NSArray *changes = [self.eventGroups addEvent:event];

		for (EventGroupChange *eventGroupChange in changes) {
			if ([eventGroupChange.type isEqualToString:EventGroupChangeUpdate]) {
				[updateIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			} else if ([eventGroupChange.type isEqualToString:EventGroupChangeInsert]) {
				[insertIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			}
		}
	}

	// Deleted Events
	NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
	NSMutableArray *deletedEvents = [NSMutableArray arrayWithArray:[deletedObjects allObjects]];

	for (Event *event in deletedEvents) {
		NSArray *changes = [self.eventGroups removeEvent:event withConditionIsInvalid:NO];

		for (EventGroupChange *eventGroupChange in changes) {
			if ([eventGroupChange.type isEqualToString:EventGroupChangeUpdate]) {
				[updateIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			} else if ([eventGroupChange.type isEqualToString:EventGroupChangeDelete]) {
				[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			}
		}
	}

	// Updated Events
    // this can generate update, insert and delete changes
	NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
	NSMutableArray *updatedEvents = [NSMutableArray arrayWithArray:[updatedObjects allObjects]];

	for (Event *event in updatedEvents) {
		NSArray *changes = [self.eventGroups updateEvent:event withConditionIsActive:NO];

		for (EventGroupChange *eventGroupChange in changes) {
			if ([eventGroupChange.type isEqualToString:EventGroupChangeUpdate]) {
				[updateIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			} else if ([eventGroupChange.type isEqualToString:EventGroupChangeDelete]) {
				[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			} else if ([eventGroupChange.type isEqualToString:EventGroupChangeInsert]) {
				[insertIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			}
		}
	}

	[self.tableView beginUpdates];

	[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
	[self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView reloadRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationNone];

	[self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.eventGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventGroupCell";

	EventGroup *eventGroup = [self.eventGroups eventGroupAtIndex:(NSUInteger)indexPath.row];

	EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.position = [self positionForTableViewCellAtindexPath:indexPath];
	[cell addEventGroup:eventGroup];

	return cell;
}

- (EventGroupTableViewCellPosition)positionForTableViewCellAtindexPath:(NSIndexPath *)indexPath {
    if ([self tableView:self.tableView numberOfRowsInSection:indexPath.section] == 1) {
        return EventGroupTableViewCellPositionAlone;
    }

    if (indexPath.row == 0) {
        return EventGroupTableViewCellPositionTop;
    }

	if ([self tableView:self.tableView numberOfRowsInSection:indexPath.section] == indexPath.row + 1) {
        return EventGroupTableViewCellPositionBottom;
    }

    return EventGroupTableViewCellPositionMiddle;
}

#pragma mark -
#pragma mark Private methods

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
	NSMutableArray *insertIndexPaths = [NSMutableArray array];
	NSMutableArray *deleteIndexPaths = [NSMutableArray array];
	NSMutableArray *updateIndexPaths = [NSMutableArray array];

    NSUInteger index = [self.eventGroups indexForActiveGroupEvent];
    if (index == NSNotFound) {
        return;
    }

    Event *event = [[self.eventGroups eventGroupAtIndex:index] activeEvent];

	NSArray *changes = [self.eventGroups updateEvent:event withConditionIsActive:YES];

	for (EventGroupChange *eventGroupChange in changes) {
		if ([eventGroupChange.type isEqualToString:EventGroupChangeUpdate]) {
			[updateIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
		} else if ([eventGroupChange.type isEqualToString:EventGroupChangeInsert]) {
			[insertIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
		} else if ([eventGroupChange.type isEqualToString:EventGroupChangeDelete]) {
			[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
		}
	}

	[self.tableView beginUpdates];

	[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
	[self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView reloadRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationNone];

	[self.tableView endUpdates];
}

@end
