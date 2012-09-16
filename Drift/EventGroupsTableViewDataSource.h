//
//  EventGroupsViewModel.h
//  Drift
//
//  Created by Mikael Hultgren on 8/25/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventGroups.h"
#import "EventGroupTableViewCell.h"

@interface EventGroupsTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic) EventGroups *eventGroups;

- (void)tableView:(UITableView *)tableView refreshCell:(EventGroupTableViewCell *)cell;
- (void)tableView:(UITableView *)tableView refreshRowsAtIndexPaths:(NSArray *)indexPaths;

@end
