//
//  EventsGroupedByDateViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "InfoHintViewDelegate.h"

@interface EventsGroupedByDateViewController : UIViewController <InfoHintViewDelegate, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIScrollView *filterView;

@end