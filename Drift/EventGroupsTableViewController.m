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
    [self.refreshControl addTarget:self
                            action:@selector(refreshView:)
                  forControlEvents:UIControlEventValueChanged];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self refreshVisibleRows];
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

- (void)refreshView:(UIRefreshControl *)refreshControll {
    [self refreshVisibleRows];

    [refreshControll endRefreshing];
}

- (void)refreshVisibleRows {
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];

    NSMutableArray *changes = [NSMutableArray array];
    for (NSIndexPath *path in visibleRows) {
        Change *change = [Change new];
        change.type = ChangeUpdate;
        change.index = path.row;

        [changes addObject:change];
    }

    [self.tableView updateWithChanges:changes];
}

@end
