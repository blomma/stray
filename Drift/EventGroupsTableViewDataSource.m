//
//  EventGroupsViewModel.m
//  Drift
//
//  Created by Mikael Hultgren on 8/25/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupsTableViewDataSource.h"
#import "EventGroupTableViewCell.h"

@interface EventGroupsTableViewDataSource ()

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;

@end

@implementation EventGroupsTableViewDataSource

- (id)init {
	if (self = [super init]) {
        self.calendar = [NSCalendar currentCalendar];
        self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
        self.standaloneWeekdaySymbols = [[NSDateFormatter new] standaloneWeekdaySymbols];
	}

	return self;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.eventGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventGroupTableViewCell";

	EventGroup *eventGroup = [self.eventGroups eventGroupAtIndex:(NSUInteger)indexPath.row];

	EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.eventGroup = eventGroup;

    [self tableView:tableView refreshCell:cell];

	return cell;
}

#pragma mark -
#pragma mark Private methods

- (BOOL)existsDataAtIndexPath:(NSIndexPath *)indexPath {
    return self.eventGroups.count > (NSUInteger)indexPath.row;
}

#pragma mark -
#pragma mark Public methods

- (void)tableView:(UITableView *)tableView refreshRowsAtIndexPaths:(NSArray *)indexPaths {
    for (NSIndexPath *indexPath in indexPaths) {
        if ([self existsDataAtIndexPath:indexPath]) {
            EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            EventGroup *eventGroup = [self.eventGroups eventGroupAtIndex:(NSUInteger)indexPath.row];

            NSDateComponents *components = eventGroup.timeActiveComponents;

            cell.hours.text   = [NSString stringWithFormat:@"%02d", components.hour];
            cell.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];

            static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
            components = [self.calendar components:unitFlags fromDate:eventGroup.groupDate];

            cell.day.text      = [NSString stringWithFormat:@"%02d", components.day];
            cell.year.text     = [NSString stringWithFormat:@"%04d", components.year];
            cell.month.text    = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
            cell.weekDay.text  = [[self.standaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString];
        }
    }
}

- (void)tableView:(UITableView *)tableView refreshCell:(EventGroupTableViewCell *)cell {
	EventGroup *eventGroup = cell.eventGroup;

	NSDateComponents *components = eventGroup.timeActiveComponents;

	cell.hours.text   = [NSString stringWithFormat:@"%02d", components.hour];
	cell.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];

	static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
	components = [self.calendar components:unitFlags fromDate:eventGroup.groupDate];

	cell.day.text      = [NSString stringWithFormat:@"%02d", components.day];
	cell.year.text     = [NSString stringWithFormat:@"%04d", components.year];
	cell.month.text    = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    cell.weekDay.text  = [[self.standaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString];
}

@end
