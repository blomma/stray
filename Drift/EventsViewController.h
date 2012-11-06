//
//  EventGroupViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventGroup.h"
#import "EventTimerControl.h"
#import "TagsTableViewController.h"

@class EventsViewController;

@protocol EventsViewControllerDelegate <NSObject>

- (void)eventsViewControllerDidDimiss:(EventsViewController *)eventsViewController;

@end

@interface EventsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, TagsTableViewControllerDelegate>

@property (nonatomic, weak) id<EventsViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIScrollView *filterView;

@end
