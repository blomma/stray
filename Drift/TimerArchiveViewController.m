//
//  TimerArchiveViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerArchiveViewController.h"
#import "TimerArchiveEventCell.h"
#import "Event.h"
#import "EventDataManager.h"

@interface TimerArchiveViewController ()

@property (nonatomic, strong) NSMutableArray *timerEvents;

@end

@implementation TimerArchiveViewController

#pragma mark -
#pragma mark private properties

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Get starting list
	self.timerEvents = [NSMutableArray new];
	[self.timerEvents addObjectsFromArray:[Event MR_findAllSortedBy:@"startDate" ascending:NO]];

	// Get notified of new things happening
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(handleDataModelChange:)
	                                             name:NSManagedObjectContextObjectsDidChangeNotification
	                                           object:[NSManagedObjectContext MR_defaultContext]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)handleDataModelChange:(NSNotification *)note;
{
	NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];

//	if ([insertedObjects count] > 0) {
		NSMutableArray *array = [NSMutableArray arrayWithArray:[insertedObjects allObjects]];
		[array sortUsingSelector:@selector(compare:)];

//		[self.tableView beginUpdates];
//
//		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];

		for (Event *event in array) {
			[self.timerEvents insertObject:event atIndex:0];
//			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
//			                      withRowAnimation:UITableViewRowAnimationTop];
		}

//		[self.tableView endUpdates];
//	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.timerEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"TimerArchiveEventCell";

	Event *event = [self.timerEvents objectAtIndex:indexPath.row];
	
	TimerArchiveEventCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	NSDate *startDate = event.startDate;
	NSDate *stopDate;
	if (event.runningValue) {
		stopDate = [NSDate date];
	} else {
		stopDate = event.stopDate;
	}

	unsigned int unitFlags       = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:startDate toDate:stopDate options:0];

	// And finally update the running timer
	cell.runningTimeHours.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:96];
	cell.runningTimeHours.text = [NSString stringWithFormat:@"%02d", components.hour];

	cell.runningTimeMinutes.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:40];
	cell.runningTimeMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];


	cell.dateDay.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:36];
	cell.dateDay.text = @"17";

	cell.dateYear.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
	cell.dateYear.text = @"2012";

	cell.dateMonth.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
	cell.dateMonth.text = @"september";

	//	cell.nameLabel.font = [UIFont fontWithName:@"LeagueGothic" size:20];
//	cell.nameLabel.text = [NSDateFormatter localizedStringFromDate:event.startDate
//														 dateStyle:NSDateFormatterShortStyle
//														 timeStyle:NSDateFormatterFullStyle];

	return cell;
}

#pragma mark - Table view delegate

@end
