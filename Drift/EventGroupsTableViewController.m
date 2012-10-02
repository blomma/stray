//
//  EventGroupsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroup.h"
#import "EventGroups.h"
#import "EventGroupsTableViewController.h"
#import "EventGroupsTableViewDataSource.h"
#import "EventGroupViewController.h"
#import "NSManagedObject+ActiveRecord.h"
#import "Tag.h"
#import "UITableView+Change.h"
#import "DataManager.h"
#import "Change.h"

@interface EventGroupsTableViewController ()

//@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) EventGroupViewController *eventGroupViewController;
@property (nonatomic) EventGroupsTableViewDataSource *dataSource;

@end

@implementation EventGroupsTableViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    DLog(@"viewDidLoad");
    EventGroupsTableViewDataSource *dataSource = [EventGroupsTableViewDataSource new];

    self.dataSource = dataSource;
    self.tableView.dataSource = dataSource;

    self.eventGroupViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EventGroupViewController"];

	// Get starting list
//    Tag *tag = [Tag where:@{ @"name" : @"Work" }].first;

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:kDataManagerDidSaveNotification
	                                           object:[DataManager instance]];

	[[[DataManager instance] eventGroups] addObserver:self
                                           forKeyPath:@"existsActiveEventGroup"
                                              options:NSKeyValueObservingOptionNew
                                              context:NULL];

	// Do an inital check to see if there is an active event group
//	if ([[DataManager instance] eventGroups].activeEventGroup) {
//		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
//															target:self
//														  selector:@selector(timerUpdate)
//														  userInfo:nil
//														   repeats:YES];
//	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    DLog(@"viewWillAppear");
//    [self updateActiveEventGroup];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [sender setSelected:NO animated:YES];

    EventGroupViewController *eventGroupViewController = [segue destinationViewController];
    EventGroup *eventGroup = [[[DataManager instance] eventGroups] eventGroupAtIndex:(NSUInteger)[self.tableView indexPathForSelectedRow].row];

    eventGroupViewController.eventGroup = eventGroup;
}

#pragma mark -
#pragma mark Private methods

- (void)dataModelDidSave:(NSNotification *)note {
    NSSet *changes = [[note userInfo] objectForKey:kEventGroupChangesKey];
    DLog(@"changes %@", changes);

    [self.tableView updateWithChanges:[changes allObjects]];
}

//- (void)timerUpdate {
//	[self updateActiveEventGroup];
//}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//	if ([keyPath isEqualToString:@"existsActiveEventGroup"]) {
//		BOOL existsActiveEventGroup = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
//		if (existsActiveEventGroup) {
//			if (!self.updateTimer.isValid) {
//				self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
//																	target:self
//																  selector:@selector(timerUpdate)
//																  userInfo:nil
//																   repeats:YES];
//			}
//		} else {
//			[self.updateTimer invalidate];
//		}
//	}
//}

//- (void)updateActiveEventGroup {
//    EventGroup *activeEventGroup = [[DataManager instance] eventGroups].activeEventGroup;
//    if (!activeEventGroup) {
//        return;
//    }
//
//    Event *event = [activeEventGroup activeEvent];
//	NSArray *changes = [[[DataManager instance] eventGroups] updateEvent:event];
//
//    [self.tableView updateWithChanges:changes];
//}

@end
