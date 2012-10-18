//
//  EventGroupViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsViewController.h"
#import "Event.h"
#import "EventTableViewCell.h"
#import "UITableView+Change.h"
#import "DataManager.h"
#import "TableViewGestureRecognizer.h"
#import "Global.h"

#define COMMITING_CREATE_CELL_HEIGHT 44

static NSString *pullDownTableViewCellIdentifier = @"pullDownTableViewCellIdentifier";

@interface EventsViewController ()<TableViewGestureAddingRowDelegate>

@property (nonatomic) TableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic) NSIndexPath *indexPathInEditState;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSDateFormatter *startDateFormatter;

@property (nonatomic) NSMutableArray *events;

@end

@implementation EventsViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.calendar = [Global instance].calendar;

    self.startDateFormatter = [[NSDateFormatter alloc] init];
    [self.startDateFormatter setDateFormat:@"HH:mm '@' d LLL, y"];

    self.events = [[NSMutableArray alloc] initWithArray:[DataManager instance].events];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:pullDownTableViewCellIdentifier];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
}

#pragma mark -
#pragma mark TableViewGestureAddingRowDelegate

- (CGFloat)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return COMMITING_CREATE_CELL_HEIGHT;
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.events insertObject:pullDownTableViewCellIdentifier atIndex:(NSUInteger)indexPath.row];

    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.events removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    [self.events removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

    if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.events.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventTableViewCell";

    id object = [self.events objectAtIndex:(NSUInteger)indexPath.row];
    if ([object isKindOfClass:[NSString class]] && [object isEqualToString:pullDownTableViewCellIdentifier] && indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pullDownTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
        cell.textLabel.backgroundColor = [UIColor clearColor];

        if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.text = @"Close";
            CGFloat alpha = 1 - (COMMITING_CREATE_CELL_HEIGHT * 2 / cell.frame.size.height);
            
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.843f
                                                               green:0.306f
                                                                blue:0.314f
                                                               alpha:alpha];
        } else {
            cell.textLabel.text = @"";
            cell.contentView.backgroundColor = [UIColor clearColor];
        }

        return cell;
    } else {
        Event *event = (Event *)object;
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
}

@end