//
//  TimerArchiveViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupsViewController.h"

#import "Event.h"
#import "EventDataManager.h"
#import "EventGroup.h"
#import "EventGroupChange.h"
#import "EventGroups.h"
#import "EventGroupTableViewCell.h"

@interface EventGroupsViewController ()

@property (nonatomic, strong) EventGroups *eventGroups;

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

//- (void)viewWillAppear:(BOOL)animated {
//	NSMutableArray *updateIndexPaths = [NSMutableArray array];
//
//	for (NSUInteger i = 0; i < [self.eventGroups count]; i++) {
//		EventGroup *eventGroup = [self.eventGroups eventGroupAtIndex:i];
//		if (eventGroup.isRunning) {
//			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)i inSection:0];
//			if ([self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
//				[updateIndexPaths addObject:indexPath];
//			}
//		}
//	}
//
//	[self.tableView beginUpdates];
//
//	[self.tableView reloadRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
//
//	[self.tableView endUpdates];
//}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Get starting list
	NSArray *events = [Event MR_findAllSortedBy:@"startDate" ascending:NO];
	self.eventGroups = [[EventGroups alloc] initWithEvents:events];

	// Get notified of new things happening
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(handleDataModelChange:)
	                                             name:NSManagedObjectContextObjectsDidChangeNotification
	                                           object:[NSManagedObjectContext MR_defaultContext]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)handleDataModelChange:(NSNotification *)note {
	NSMutableArray *insertIndexPaths = [NSMutableArray array];
	NSMutableArray *deleteIndexPaths = [NSMutableArray array];
	NSMutableArray *updateIndexPaths = [NSMutableArray array];

	// Inserted Events
	NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
	NSMutableArray *insertedEvents = [NSMutableArray arrayWithArray:[insertedObjects allObjects]];
	DLog(@"insertedEvents %d", insertedEvents.count);

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
	DLog(@"deletedEvents %d", deletedEvents.count);

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
	NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
	NSMutableArray *updatedEvents = [NSMutableArray arrayWithArray:[updatedObjects allObjects]];
	DLog(@"updatedEvents %d", updatedEvents.count);

	for (Event *event in updatedEvents) {
		NSArray *changes = [self.eventGroups updateEvent:event];

		for (EventGroupChange *eventGroupChange in changes) {
			if ([eventGroupChange.type isEqualToString:EventGroupChangeUpdate]) {
				[updateIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventGroupChange.index inSection:0]];
			}
		}
	}

	[self.tableView beginUpdates];

	[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
	[self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView reloadRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationLeft];

	[self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	DLog(@"count %d", self.eventGroups.count);
	return (NSInteger)self.eventGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventGroupCell";

	EventGroup *eventGroup = [self.eventGroups eventGroupAtIndex:(NSUInteger)indexPath.row];

	DLog(@"row %d", indexPath.row);
	EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	cell.runningTimeHours.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:96];
	cell.runningTimeMinutes.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:40];
	cell.dateDay.font            = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:36];
	cell.dateYear.font           = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
	cell.dateMonth.font          = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];

	[cell addEventGroup:eventGroup];

	return cell;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	[(EventGroupTableViewCell *)cell].runningTimeHours.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:96];
//
//	self.runningTimeMinutes.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:40];
//	self.dateDay.font            = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:36];
//	self.dateYear.font           = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
//	self.dateMonth.font          = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
//
//	// If the cell contains a eventGroup that is still running then we need to update it
//	if ([(EventGroupTableViewCell *)cell eventGroup].isRunning) {
//		[(EventGroupTableViewCell *)cell updateTime];
//	}
//}

#pragma mark - Table view delegate

@end
