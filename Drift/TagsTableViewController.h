//
//  TagsTableViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

@class TagsTableViewController;

@interface TagsTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, copy) void (^didDismissHandler)(void);
@property (nonatomic) NSString *eventGUID;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
