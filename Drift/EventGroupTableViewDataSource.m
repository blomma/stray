//
//  EventGroupViewDataSource.m
//  Drift
//
//  Created by Mikael Hultgren on 9/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupTableViewDataSource.h"
#import "Event.h"
#import "EventTableViewCell.h"
#import "NSManagedObject+ActiveRecord.h"
#import "Change.h"

@interface EventGroupTableViewDataSource ()

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSDateFormatter *startDateFormatter;

@end

@implementation EventGroupTableViewDataSource

- (id)init {
    self = [super init];
	if (self) {
        self.calendar = [NSCalendar currentCalendar];

        self.startDateFormatter = [[NSDateFormatter alloc] init];
        [self.startDateFormatter setDateFormat:@"HH:mm '@' d LLL, y"];
	}

	return self;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.eventGroup.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventTableViewCell";

    Event *event = [self.eventGroup.events objectAtIndex:(NSUInteger)indexPath.row];
	EventTableViewCell *cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    cell.eventStart.text = [self.startDateFormatter stringFromDate:event.startDate];

    if ([event isActive]) {
        cell.eventStop.text = @"";
    } else {
        cell.eventStop.text = [self.startDateFormatter stringFromDate:event.stopDate];
    }

    NSDate *stopDate = event.stopDate;
    if ([event isActive]) {
        stopDate = [NSDate date];
    }

	static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit;
    NSDateComponents *components = [self.calendar components:unitFlags
                                                    fromDate:event.startDate
                                                      toDate:stopDate
                                                     options:0];

    cell.eventTime.text = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];

	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Event *event = [self.eventGroup.events objectAtIndex:(NSUInteger)indexPath.row];
        [event delete];
    }
}

#pragma mark -
#pragma mark Public methods

- (void)tableView:(UITableView *)tableView refreshCellForEvent:(Event *)event atIndexPath:(NSIndexPath *)indexPath {
    EventTableViewCell *cell = (EventTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];

    cell.eventStart.text = [self.startDateFormatter stringFromDate:event.startDate];

    if ([event isActive]) {
        cell.eventStop.text = @"";
    } else {
        cell.eventStop.text = [self.startDateFormatter stringFromDate:event.stopDate];
    }

    NSDate *stopDate = event.stopDate;
    if ([event isActive]) {
        stopDate = [NSDate date];
    }

	static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit;
    NSDateComponents *components = [self.calendar components:unitFlags
                                                    fromDate:event.startDate
                                                      toDate:stopDate
                                                     options:0];

    cell.eventTime.text = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
}

- (void)tableView:(UITableView *)tableView refreshCellForEvent:(Event *)event {
    NSUInteger index = [self.eventGroup.events indexOfObject:event];

    if (index == NSNotFound) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];

    [self tableView:tableView refreshCellForEvent:event atIndexPath:path];
}

- (Event *)eventAtIndex:(NSUInteger)index {
    return [self.eventGroup.events objectAtIndex:index];
}

#pragma mark -
#pragma mark Private methods

@end
