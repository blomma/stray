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
#import "DataManager.h"
#import "Global.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "EventTableViewCell.h"
#import "SKBounceAnimation.h"
#import "CAAnimation+Blocks.h"
#import "TagsTableViewController.h"

static NSInteger kEditCommitLength = 120;
static NSInteger kAddingCommitHeight = 74;

static NSString *pullDownTableViewCellIdentifier = @"pullDownTableViewCellIdentifier";

@interface EventsViewController ()<TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGestureAddingRowDelegate, EventTableViewCellDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSMutableArray *events;

@end

@implementation EventsViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.calendar = [Global instance].calendar;

    self.events = [[NSMutableArray alloc] initWithArray:[DataManager instance].events];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:pullDownTableViewCellIdentifier];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvents"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Event *event = [self.events objectAtIndex:(NSUInteger)indexPath.row];

        if ([[segue destinationViewController] respondsToSelector:@selector(event)]) {
            [[segue destinationViewController] setEvent:event];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

#pragma mark -
#pragma mark EventTableViewCellDelegate

- (void)cell:(UITableViewCell *)cell tappedTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
   [self performSegueWithIdentifier:@"segueToTagsFromEvents" sender:cell];
}

#pragma mark -
#pragma mark TableViewGestureAddingRowDelegate

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return kAddingCommitHeight;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.events insertObject:pullDownTableViewCellIdentifier atIndex:(NSUInteger)indexPath.row];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.events removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    [self.events removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

    if (cell.frame.size.height > kAddingCommitHeight * 2) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark TableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (state == TransformableTableViewCellEditingStateLeft) {
        return;
    }

    EventTableViewCell *cell = (EventTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.layer removeAllAnimations];

    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.contentView.frame];
    cell.backgroundView = backgroundView;
    cell.backgroundView.backgroundColor = [UIColor colorWithRed:0.843f
                                                          green:0.306f
                                                           blue:0.314f
                                                          alpha:1];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (state == TransformableTableViewCellEditingStateLeft) {
        return;
    }

    EventTableViewCell *cell = (EventTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    CGFloat alpha = 1 - (gestureRecognizer.translationInTableView.x / kEditCommitLength);
    cell.contentView.alpha = alpha;

    CGPoint point = CGPointMake(CGRectGetMidX(cell.layer.bounds) + gestureRecognizer.translationInTableView.x, cell.layer.position.y);
    cell.layer.position = point;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (state == TransformableTableViewCellEditingStateLeft) {
        return;
    }

    EventTableViewCell *cell = (EventTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.alpha = 1;

    Event *event = [self.events objectAtIndex:(NSUInteger)indexPath.row];
    [[DataManager instance] deleteEvent:event];
    [self.events removeObject:event];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    EventTableViewCell *cell = (EventTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    CGPoint fromValue = cell.layer.position;
    CGPoint toValue = CGPointMake(CGRectGetMidX(cell.layer.bounds), fromValue.y);

    cell.contentView.alpha = 1;
    [self animateBounceOnLayer:cell.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return kEditCommitLength;
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

        if (cell.frame.size.height > kAddingCommitHeight * 2) {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.text = @"Close";
            CGFloat alpha = 1 - (kAddingCommitHeight * 2 / cell.frame.size.height);

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
        cell.contentView.backgroundColor = [UIColor colorWithWhite:0.075 alpha:1.000];

        // Tag
        NSString *tagName = event.inTag ? event.inTag.name : @"";
        [cell.tagName setTitle:[tagName uppercaseString] forState:UIControlStateNormal];

        // StartTime
        static NSUInteger unitFlagsEventStart = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
        NSDateComponents *components = [self.calendar components:unitFlagsEventStart fromDate:event.startDate];

        cell.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
        cell.eventStartDay.text   = [NSString stringWithFormat:@"%02d", components.day];
        cell.eventStartYear.text  = [NSString stringWithFormat:@"%04d", components.year];
        cell.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];

        // EventTime
        NSDate *stopDate = event.stopDate ? event.stopDate : [NSDate date];
        static NSUInteger unitFlagsEventTime = NSHourCalendarUnit | NSMinuteCalendarUnit;
        components = [self.calendar components:unitFlagsEventTime fromDate:event.startDate toDate:stopDate options:0];

        cell.eventTimeHours.text   = [NSString stringWithFormat:@"%02d", components.hour];
        cell.eventTimeMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];

        // StopTime
        if (event.stopDate) {
            static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
            components = [self.calendar components:unitFlags fromDate:event.stopDate];

            cell.eventStopTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
            cell.eventStopDay.text   = [NSString stringWithFormat:@"%02d", components.day];
            cell.eventStopYear.text  = [NSString stringWithFormat:@"%04d", components.year];
            cell.eventStopMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
        } else {
            cell.eventStopTime.text  = @"";
            cell.eventStopDay.text   = @"";
            cell.eventStopYear.text  = @"";
            cell.eventStopMonth.text = @"";
        }

        cell.delegate = self;

        return cell;
    }
}

#pragma mark -
#pragma mark Private methods

- (void)animateBounceOnLayer:(CALayer *)layer fromPoint:(CGPoint)from toPoint:(CGPoint)to withDuration:(CFTimeInterval)duration completion:(void (^)(BOOL finished))completion{
    static NSString *keyPath = @"position";

	SKBounceAnimation *positionAnimation = [SKBounceAnimation animationWithKeyPath:keyPath];
	positionAnimation.fromValue = [NSValue valueWithCGPoint:from];
	positionAnimation.toValue = [NSValue valueWithCGPoint:to];
	positionAnimation.duration = duration;
	positionAnimation.numberOfBounces = 4;
    positionAnimation.completion = completion;

	[layer addAnimation:positionAnimation forKey:@"someKey2"];
	[layer setValue:[NSValue valueWithCGPoint:to] forKeyPath:keyPath];
}

@end