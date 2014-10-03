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

@interface EventsGroupedByStartDateViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) void (^didDismissHandler)(void);
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
