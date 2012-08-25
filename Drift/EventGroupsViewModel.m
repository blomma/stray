//
//  EventGroupsViewModel.m
//  Drift
//
//  Created by Mikael Hultgren on 8/25/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupsViewModel.h"
#import "EventGroupTableViewCell.h"

@interface EventGroupsViewModel ()

@end

@implementation EventGroupsViewModel

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.eventGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventGroupCell";

	EventGroup *eventGroup = [self.eventGroups eventGroupAtIndex:(NSUInteger)indexPath.row];

	EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.position = [self positionForTableView:tableView AtindexPath:indexPath];
	[cell addEventGroup:eventGroup];

	return cell;
}

- (EventGroupTableViewCellPosition)positionForTableView:(UITableView *)tableView  AtindexPath:(NSIndexPath *)indexPath {
    if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 1) {
        return EventGroupTableViewCellPositionAlone;
    }

    if (indexPath.row == 0) {
        return EventGroupTableViewCellPositionTop;
    }

	if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == indexPath.row + 1) {
        return EventGroupTableViewCellPositionBottom;
    }

    return EventGroupTableViewCellPositionMiddle;
}


@end
