//
//  EventGroupViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsGroupedByStartDateViewController.h"

#import "CAAnimation+Blocks.h"
#import "DataRepository.h"
#import "Event.h"
#import "EventsGroupedByStartDateTableViewCell.h"
#import "Global.h"
#import "SKBounceAnimation.h"
#import "TagFilterButton.h"
#import "Tags.h"
#import "TagsTableViewController.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "UIScrollView+SVPulling.h"
#import "EventsGroupedByStartDate.h"

@interface EventsGroupedByStartDateViewController ()<TransformableTableViewGestureEditingRowDelegate, EventsGroupedByStartDateTableViewCellDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *shortStandaloneWeekdaySymbols;

@property (nonatomic) NSMutableArray *filterViewButtons;

@property (nonatomic) Tags *tags;
@property (nonatomic) BOOL isTagsInvalid;

@property (nonatomic) State *state;

@property (nonatomic) EventsGroupedByStartDate *eventGroups;
@property (nonatomic) BOOL isEventGroupsInvalid;

@property (nonatomic, readonly) NSInteger editingCommitLength;

@end

@implementation EventsGroupedByStartDateViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.calendar                      = [Global instance].calendar;
    self.shortStandaloneMonthSymbols   = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.shortStandaloneWeekdaySymbols = [[NSDateFormatter new] shortStandaloneWeekdaySymbols];

    self.state = [DataRepository instance].state;

    self.tags          = [DataRepository instance].tags;
    self.isTagsInvalid = YES;

    [self initFilterView];

    self.eventGroups = [[EventsGroupedByStartDate alloc] initWithEvents:[DataRepository instance].events
                                                            withFilters:self.state.eventsFilter];
    self.isEventGroupsInvalid = YES;

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    __block __weak EventsGroupedByStartDateViewController *weakSelf = self;

    [self.tableView addPullingWithActionHandler:^(SVPullingState state, SVPullingState previousState, CGFloat height) {
        if (state == SVPullingStateAction && (previousState == SVPullingStatePullingAdd || previousState == SVPullingStatePullingClose)) {
            if ([weakSelf.delegate respondsToSelector:@selector(tagsTableViewControllerDidDimiss:)]) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 200000000);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    [weakSelf.delegate eventsGroupedByStartDateViewControllerDidDimiss:weakSelf];
                });
            }
        }

        CGRect frame = CGRectMake(0, MIN(0, height), self.view.bounds.size.width, 30);
        self.filterView.frame = frame;
    }];

    self.tableView.pullingView.addingHeight  = 0;
    self.tableView.pullingView.closingHeight = 60;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(objectsDidChange:)
                                                 name:kDataManagerObjectsDidChangeNotification
                                               object:[DataRepository instance]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForegroundNotification:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    if (self.isTagsInvalid) {
        [self setupFilterView];
    }

    [self.tableView reloadData];

    NSIndexPath *indexPath = [self.eventGroups indexPathOfFilteredEvent:self.state.activeEvent];
    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];

    // Check if we disapeared because of presenting a controller
    if (!self.presentedViewController) {
        [self.tableView disablePulling];

        [self.tableView disableGestureTableViewWithRecognizer:self.tableViewRecognizer];
        self.tableViewRecognizer = nil;

        for (id subView in self.filterViewButtons) {
            [subView removeFromSuperview];
        }
        [self.filterViewButtons removeAllObjects];

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kDataManagerObjectsDidChangeNotification
                                                      object:[DataRepository instance]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvents"]) {
        [[segue destinationViewController] setDelegate:self];

        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Event *event           = [self.eventGroups filteredEventAtIndexPath:indexPath];

        if ([[segue destinationViewController] respondsToSelector:@selector(event)]) {
            [[segue destinationViewController] setEvent:event];
        }
    }
}

#pragma mark -
#pragma mark Private properties

- (NSInteger)editingCommitLength {
    return 200;
}

#pragma mark -
#pragma mark Public properties

- (EventsGroupedByStartDate *)eventGroups {
    if (self.isEventGroupsInvalid) {
        _eventGroups.filters      = self.state.eventsFilter;
        self.isEventGroupsInvalid = NO;
    }

    return _eventGroups;
}

#pragma mark -
#pragma mark TagsTableViewControllerDelegate

- (void)tagsTableViewControllerDidDimiss:(TagsTableViewController *)tagsTableViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark EventTableViewCellDelegate

- (void)cell:(UITableViewCell *)cell tappedTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
    [self performSegueWithIdentifier:@"segueToTagsFromEvents" sender:cell];
}

#pragma mark -
#pragma mark TransformableTableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (state == TransformableTableViewCellEditingStateLeft) {
        return;
    }

    EventsGroupedByStartDateTableViewCell *cell = (EventsGroupedByStartDateTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.frontView.layer removeAllAnimations];

    cell.willDelete.hidden = YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (state == TransformableTableViewCellEditingStateLeft) {
        return;
    }

    EventsGroupedByStartDateTableViewCell *cell = (EventsGroupedByStartDateTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    CGFloat alpha                               = (gestureRecognizer.translationInTableView.x / self.editingCommitLength);
    cell.backView.backgroundColor = [UIColor colorWithRed:0.843f
                                                    green:0.306f
                                                     blue:0.314f
                                                    alpha:alpha];

    cell.willDelete.hidden = alpha >= 1 ? NO : YES;

    CGPoint point = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + gestureRecognizer.translationInTableView.x, cell.frontView.layer.position.y);
    cell.frontView.layer.position = point;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (state == TransformableTableViewCellEditingStateLeft) {
        return;
    }

    EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)indexPath.section];
    Event *event           = [eventGroup.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];

    // Are we about to remove the active event
    if ([self.state.activeEvent isEqual:event]) {
        self.state.activeEvent = nil;
    }

    [[DataRepository instance] deleteEvent:event];
    [self.eventGroups removeEvent:event];

    [self.tableView beginUpdates];

    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    if (eventGroup.filteredEvents.count == 0) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:(NSUInteger)indexPath.section] withRowAnimation:UITableViewRowAnimationRight];
    }

    [self.tableView endUpdates];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    EventsGroupedByStartDateTableViewCell *cell = (EventsGroupedByStartDateTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    CGPoint fromValue                           = cell.frontView.layer.position;
    CGPoint toValue                             = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.editingCommitLength;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)section];

    CGRect frame = CGRectMake(0, 0.0, tableView.bounds.size.width, 36.0);

    UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
    headerLabel.backgroundColor = [UIColor colorWithRed:0.745 green:0.106 blue:0.169 alpha:0.8];
    headerLabel.opaque          = YES;
    headerLabel.textColor       = [UIColor whiteColor];
    headerLabel.font            = [UIFont fontWithName:@"Futura-CondensedMedium" size:16];
    headerLabel.textAlignment   = NSTextAlignmentCenter;

    static NSUInteger unitFlagsEventStart = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *components          = [self.calendar components:unitFlagsEventStart fromDate:eventGroup.groupDate];

    headerLabel.text = [NSString stringWithFormat:@"%@  ·  %02d %@ %04d", [[self.shortStandaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString], components.day, [[self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1] uppercaseString], components.year];

    return headerLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 36;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Event *event = [self.eventGroups filteredEventAtIndexPath:indexPath];

    self.state.activeEvent = event;

    if ([self.delegate respondsToSelector:@selector(eventsGroupedByStartDateViewControllerDidDimiss:)]) {
        [self.delegate eventsGroupedByStartDateViewControllerDidDimiss:self];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.eventGroups.filteredEventGroupCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)section];
    return (NSInteger)eventGroup.filteredEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"EventsGroupedByStartDateTableViewCell";

    Event *event = [self.eventGroups filteredEventAtIndexPath:indexPath];

    EventsGroupedByStartDateTableViewCell *cell = (EventsGroupedByStartDateTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [cell.tagName setTitle:event.inTag.name forState:UIControlStateNormal];

    // StartTime
    static NSUInteger unitFlagsEventStart = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
    NSDateComponents *components          = [self.calendar components:unitFlagsEventStart fromDate:event.startDate];

    cell.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
    cell.eventStartDay.text   = [NSString stringWithFormat:@"%02d", components.day];
    cell.eventStartYear.text  = [NSString stringWithFormat:@"%04d", components.year];
    cell.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];

    // EventTime
    NSDate *stopDate                     = event.stopDate ? event.stopDate : [NSDate date];
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

#pragma mark -
#pragma mark Private methods

- (void)objectsDidChange:(NSNotification *)note {
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *deletedObjects  = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *updatedObjects  = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

    // ========
    // = Tags =
    // ========
    NSSet *updatedTags = [updatedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Tag class]];
        }];

    NSSet *insertedTags = [insertedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Tag class]];
        }];

    [self.tags addObjectsFromArray:[insertedTags allObjects]];

    NSSet *deletedTags = [deletedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Tag class]];
        }];

    [self.tags removeObjectsInArray:[deletedTags allObjects]];

    if (updatedTags.count > 0 || insertedTags.count > 0 || deletedTags.count > 0) {
        self.isTagsInvalid = YES;
    }

    if ([deletedTags intersectsSet:self.state.eventsFilter]) {
        self.isEventGroupsInvalid = YES;
    }
}

- (void)appWillEnterForegroundNotification:(NSNotification *)note {
    [self.tableView reloadData];
}

- (void)touchUpInsideTagFilterButton:(TagFilterButton *)sender forEvent:(UIEvent *)event {
    if ([self.state.eventsFilter containsObject:sender.tagObject]) {
        [self.state.eventsFilter removeObject:sender.tagObject];

        sender.selected = NO;
    } else {
        [self.state.eventsFilter addObject:sender.tagObject];

        sender.selected = YES;
    }

    self.isEventGroupsInvalid = YES;

    [self.tableView reloadData];

    NSIndexPath *indexPath = [self.eventGroups indexPathOfFilteredEvent:self.state.activeEvent];
    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)initFilterView {
    self.filterViewButtons = [NSMutableArray array];

    self.filterView.showsHorizontalScrollIndicator = NO;
    self.filterView.backgroundColor                = [UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:0.9];

    UIColor *colorOne = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:0.3f];
    UIColor *colorTwo = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:1];

    NSArray *colors = @[(id)colorOne.CGColor, (id)colorTwo.CGColor, (id)colorTwo.CGColor, (id)colorOne.CGColor];

    NSArray *locations = @[@0.0, @0.4, @0.6, @1.0];

    CAGradientLayer *barrier = [CAGradientLayer layer];
    barrier.colors     = colors;
    barrier.locations  = locations;
    barrier.startPoint = CGPointMake(0, 0.5);
    barrier.endPoint   = CGPointMake(1.0, 0.5);

    barrier.bounds = CGRectMake(0, 0, self.filterView.layer.bounds.size.width, 1);
    CGPoint position = self.filterView.layer.position;
    position.y         += 14;
    barrier.position    = position;
    barrier.anchorPoint = self.filterView.layer.anchorPoint;

    [self.filterView.layer addSublayer:barrier];
}

- (void)setupFilterView {
    // Remove all the old subviews and recreate them, lazy option
    for (id subView in self.filterViewButtons) {
        [subView removeFromSuperview];
    }

    [self.filterViewButtons removeAllObjects];

    // define number and size of elements
    NSUInteger numElements  = 0;
    CGSize elementSize      = CGSizeMake(120, self.filterView.frame.size.height);
    UIEdgeInsets titleInset = UIEdgeInsetsMake(0, 5, 0, 5);

    // add elements
    for (NSUInteger i = 0; i < self.tags.count; i++) {
        Tag *tag = [self.tags objectAtIndex:i];

        if (tag.name) {
            TagFilterButton *button = [[TagFilterButton alloc] init];
            button.tagObject = tag;
            [button addTarget:self action:@selector(touchUpInsideTagFilterButton:forEvent:) forControlEvents:UIControlEventTouchUpInside];

            button.titleLabel.font            = [UIFont fontWithName:@"Futura-Medium" size:13];
            button.titleLabel.backgroundColor = [UIColor clearColor];
            button.titleLabel.lineBreakMode   = NSLineBreakByTruncatingTail;

            button.backgroundColor = [UIColor clearColor];

            button.titleEdgeInsets = titleInset;

            [button setTitleColor:[UIColor colorWithWhite:0.392f alpha:1.000] forState:UIControlStateNormal];
            [button setTitle:[tag.name uppercaseString] forState:UIControlStateNormal];

            // setup frames to appear besides each other in the slider
            CGFloat elementX = elementSize.width * numElements;
            button.frame = CGRectMake(elementX, 0, elementSize.width, elementSize.height);

            if ([self.state.eventsFilter containsObject:tag]) {
                button.selected = YES;
            }

            [self.filterViewButtons addObject:button];

            // add the subview
            [self.filterView addSubview:button];
            numElements++;
        }
    }

    // set the size of the scrollview's content
    self.filterView.contentSize = CGSizeMake(numElements * elementSize.width, elementSize.height);

    self.isTagsInvalid        = NO;
    self.isEventGroupsInvalid = YES;
}

- (void)animateBounceOnLayer:(CALayer *)layer fromPoint:(CGPoint)from toPoint:(CGPoint)to withDuration:(CFTimeInterval)duration completion:(void (^)(BOOL finished))completion {
    static NSString *keyPath = @"position";

    SKBounceAnimation *positionAnimation = [SKBounceAnimation animationWithKeyPath:keyPath];
    positionAnimation.fromValue       = [NSValue valueWithCGPoint:from];
    positionAnimation.toValue         = [NSValue valueWithCGPoint:to];
    positionAnimation.duration        = duration;
    positionAnimation.numberOfBounces = 4;
    positionAnimation.completion      = completion;

    [layer addAnimation:positionAnimation forKey:keyPath];
    [layer setValue:[NSValue valueWithCGPoint:to] forKeyPath:keyPath];
}

@end