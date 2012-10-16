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

@interface EventsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
