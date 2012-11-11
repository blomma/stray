//
//  EventGroupViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsViewController.h"

#import "CAAnimation+Blocks.h"
#import "DataRepository.h"
#import "Event.h"
#import "EventTableViewCell.h"
#import "Global.h"
#import "SKBounceAnimation.h"
#import "TagButton.h"
#import "Tags.h"
#import "TagsTableViewController.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "UIScrollView+SVPulling.h"
#import "EventsGroupedByStartDate.h"

static NSString *eventTableViewCellIdentifier = @"eventTableViewCellIdentifier";

@interface EventsViewController ()<TransformableTableViewGestureEditingRowDelegate, EventTableViewCellDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *shortStandaloneWeekdaySymbols;

@property (nonatomic) NSMutableArray *filterViewButtons;

@property (nonatomic) Tags *tags;
@property (nonatomic) BOOL isTagsInvalid;
@property (nonatomic, readonly) BOOL isFilterViewVisible;

@property (nonatomic) UIState *state;

@property (nonatomic) EventsGroupedByStartDate *eventGroups;
@property (nonatomic) BOOL isEventGroupsInvalid;

@property (nonatomic, readonly) NSInteger editingCommitLength;

@end

@implementation EventsViewController

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

    __block __weak EventsViewController *weakSelf = self;

    [self.tableView addPullingWithActionHandler:^(SVPullingState state, CGFloat height) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 200000000);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            if (state == SVPullingStateTriggeredClose) {
                if ([weakSelf.delegate respondsToSelector:@selector(tagsTableViewControllerDidDimiss:)]) {
                    [weakSelf.delegate eventsViewControllerDidDimiss:weakSelf];
                }
            }
        });
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

    if (self.isTagsInvalid) {
        [self setupFilterView];
    }

    [self.tableView reloadData];

    NSIndexPath *indexPath = [self.eventGroups indexPathOfFilteredEvent:self.state.activeEvent];

    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    CGFloat y    = self.isFilterViewVisible ? 0 : -30;
    CGRect frame = CGRectMake(0, y, self.view.bounds.size.width, 30);

    [UIView animateWithDuration:0.3 animations:^{
        self.filterView.frame = frame;
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    // Check if we disapeared because of presenting a tag controller
    if (!self.presentedViewController) {
        [self.tableView disablePulling];

        [self.tableView disableGestureTableViewWithRecognizer:self.tableViewRecognizer];
        self.tableViewRecognizer = nil;

        for (id subView in self.filterViewButtons) {
            [subView removeFromSuperview];
        }
        [self.filterViewButtons removeAllObjects];
        self.isTagsInvalid = YES;

        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDataManagerObjectsDidChangeNotification object:[DataRepository instance]];
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

- (BOOL)isFilterViewVisible {
    return self.tags.count > 0;
}

- (NSInteger)editingCommitLength {
    return 120;
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
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.isFilterViewVisible) {
        CGRect frame = CGRectMake(0, -30, self.view.bounds.size.width, 30);

        [UIView animateWithDuration:0.3 animations:^{
            self.filterView.frame = frame;
        }];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        if (self.isFilterViewVisible) {
            CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 30);

            [UIView animateWithDuration:0.3 animations:^{
                self.filterView.frame = frame;
            }];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.isFilterViewVisible) {
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 30);

        [UIView animateWithDuration:0.3 animations:^{
            self.filterView.frame = frame;
        }];
    }
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

    EventTableViewCell *cell = (EventTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.layer removeAllAnimations];

    if (!cell.backgroundView) {
        cell.backgroundView                 = [[UIView alloc] initWithFrame:cell.contentView.frame];
        cell.backgroundView.backgroundColor = [UIColor colorWithRed:0.843f
                                                              green:0.306f
                                                               blue:0.314f
                                                              alpha:1];
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (state == TransformableTableViewCellEditingStateLeft) {
        return;
    }

    EventTableViewCell *cell = (EventTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    CGFloat alpha            = 1 - (gestureRecognizer.translationInTableView.x / self.editingCommitLength);
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

    EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)indexPath.section];
    Event *event           = [eventGroup.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];

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
    EventTableViewCell *cell = (EventTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    CGPoint fromValue        = cell.layer.position;
    CGPoint toValue          = CGPointMake(CGRectGetMidX(cell.layer.bounds), fromValue.y);

    cell.contentView.alpha = 1;

    [self animateBounceOnLayer:cell.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];
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

    if ([self.delegate respondsToSelector:@selector(eventsViewControllerDidDimiss:)]) {
        [self.delegate eventsViewControllerDidDimiss:self];
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
    Event *event = [self.eventGroups filteredEventAtIndexPath:indexPath];

    EventTableViewCell *cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:eventTableViewCellIdentifier];
    cell.contentView.backgroundColor = [UIColor colorWithRed:0.941 green:0.933 blue:0.925 alpha:1.000];

    // Tag
    NSString *tagName = event.inTag ? event.inTag.name : @"-- --";
    [cell.tagName setTitle:[tagName uppercaseString] forState:UIControlStateNormal];

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

- (void)touchUpInsideTagFilterButton:(TagButton *)sender forEvent:(UIEvent *)event {
    if ([self.state.eventsFilter containsObject:sender.tagObject]) {
        [self.state removeEventsFilterObject:sender.tagObject];

        sender.selected = NO;
    } else {
        [self.state addEventsFilterObject:sender.tagObject];

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
    self.filterView.backgroundColor                = [UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:0.90];

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
    position.y         += 15;
    barrier.position    = position;
    barrier.anchorPoint = self.filterView.layer.anchorPoint;

    [self.filterView.layer addSublayer:barrier];
}

- (void)setupFilterView {
    if (self.isFilterViewVisible) {
        UIEdgeInsets contentInset = self.tableView.contentInset;
        contentInset.top = 30;

        self.tableView.contentInset = contentInset;
    } else {
        self.tableView.contentInset = UIEdgeInsetsZero;
    }

    // Remove all the old subviews and recreate them, lazy option
    for (id subView in self.filterViewButtons) {
        [subView removeFromSuperview];
    }

    [self.filterViewButtons removeAllObjects];

    // define number and size of elements
    NSUInteger numElements = self.tags.count;
    CGSize elementSize     = CGSizeMake(120, self.filterView.frame.size.height);

    // add elements
    for (NSUInteger i = 0; i < numElements; i++) {
        Tag *tag = [self.tags objectAtIndex:i];

        TagButton *tagButton = [TagButton buttonWithType:UIButtonTypeCustom];
        tagButton.tagObject = tag;
        [tagButton addTarget:self action:@selector(touchUpInsideTagFilterButton:forEvent:) forControlEvents:UIControlEventTouchUpInside];

        tagButton.titleLabel.font            = [UIFont fontWithName:@"Futura-Medium" size:15];
        tagButton.titleLabel.backgroundColor = [UIColor clearColor];
        tagButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        tagButton.backgroundColor = [UIColor clearColor];

        [tagButton setTitleColor:[UIColor colorWithRed:0.333f green:0.333f blue:0.333f alpha:1] forState:UIControlStateNormal];
        [tagButton setTitle:[tag.name uppercaseString] forState:UIControlStateNormal];

        // setup frames to appear besides each other in the slider
        CGFloat elementX = elementSize.width * i;
        tagButton.frame = CGRectMake(elementX, 0, elementSize.width, elementSize.height);

        if ([self.state.eventsFilter containsObject:tag]) {
            tagButton.selected = YES;
        }

        [self.filterViewButtons addObject:tagButton];

        // add the subview
        [self.filterView addSubview:tagButton];
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