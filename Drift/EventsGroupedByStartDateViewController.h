//
//  EventsGroupedByStartDateViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"
#import "TagsTableViewController.h"

@class EventsGroupedByStartDateViewController;

@protocol EventsGroupedByStartDateViewControllerDelegate <NSObject>

- (void)eventsGroupedByStartDateViewControllerDidDimiss;

@end

@interface EventsGroupedByStartDateViewController : UIViewController <NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, TagsTableViewControllerDelegate>

@property (nonatomic, weak) id<EventsGroupedByStartDateViewControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIScrollView *filterView;

@end
