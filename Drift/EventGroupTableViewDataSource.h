//
//  EventGroupViewDataSource.h
//  Drift
//
//  Created by Mikael Hultgren on 9/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventGroup.h"
#import "EventTableViewCell.h"

@interface EventGroupTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic) EventGroup *eventGroup;

- (void)tableView:(UITableView *)tableView refreshCell:(EventTableViewCell *)cell;
- (Event *)eventAtIndex:(NSUInteger)index;

@end
