//
//  EventGroupViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsViewController.h"

#import "CAAnimation+Blocks.h"
#import "DataManager.h"
#import "Event.h"
#import "EventTableViewCell.h"
#import "Events.h"
#import "Global.h"
#import "SKBounceAnimation.h"
#import "TagButton.h"
#import "Tags.h"
#import "TagsTableViewController.h"
#import "TransformableTableViewGestureRecognizer.h"

static NSString *pullingTableViewCellIdentifier = @"pullingTableViewCellIdentifier";
static NSString *eventTableViewCellIdentifier = @"eventTableViewCellIdentifier";

@interface EventsViewController ()<TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGesturePullingRowDelegate, EventTableViewCellDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;

@property (nonatomic) NSMutableArray *filterViewButtons;

@property (nonatomic) Tags *tags;
@property (nonatomic) BOOL isTagsInvalid;
@property (nonatomic, readonly) BOOL isFilterViewVisible;

@property (nonatomic) UIState *state;

@property (nonatomic) Events *events;
@property (nonatomic) BOOL isEventsInvalid;

@property (nonatomic) NSIndexPath *transformingPullingIndexPath;

@property (nonatomic, readonly) NSInteger pullingCommitHeight;
@property (nonatomic, readonly) NSInteger editingCommitLength;

@end

@implementation EventsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.calendar = [Global instance].calendar;
    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];

    self.state = [DataManager instance].state;

    self.tags = [[Tags alloc] initWithTags:[[DataManager instance] tags]];
    self.isTagsInvalid = YES;

    [self initFilterView];

    self.events = [[Events alloc] initWithEvents:[DataManager instance].events];
    self.isEventsInvalid = YES;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:pullingTableViewCellIdentifier];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(objectsDidChange:)
	                                             name:kDataManagerObjectsDidChangeNotification
	                                           object:[DataManager instance]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvents"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSUInteger adjustedIndex = [self adjustedIndexForIndexPath:indexPath];
        Event *event = [self.events.filteredEvents objectAtIndex:adjustedIndex];

        if ([[segue destinationViewController] respondsToSelector:@selector(event)]) {
            [[segue destinationViewController] setEvent:event];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isTagsInvalid) {
        [self setupFilterView];
    }

    [self.tableView reloadData];

    NSUInteger index = [self.events.filteredEvents indexOfObject:self.state.activeEvent];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [self adjustedIndexPathForIndex:index];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    CGFloat y = self.isFilterViewVisible ? 0 : -30;
    CGRect frame = CGRectMake(0, y, self.view.bounds.size.width, 30);

    [UIView animateWithDuration:0.3 animations:^{
        self.filterView.frame = frame;
    }];
}

#pragma mark -
#pragma mark Private properties

- (BOOL)isFilterViewVisible {
    return self.tags.count > 0;
}

- (NSInteger)pullingCommitHeight {
    return self.isFilterViewVisible ? 30 : 60;
}

- (NSInteger)editingCommitLength {
    return 120;
}

#pragma mark -
#pragma mark Public properties

- (Events *)events {
    if (self.isEventsInvalid) {
        _events.filters = self.state.eventsFilter;
        self.isEventsInvalid = NO;
    }

    return _events;
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
#pragma mark TransformableTableViewGesturePullingRowDelegate

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.pullingCommitHeight;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    self.transformingPullingIndexPath = indexPath;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    self.transformingPullingIndexPath = nil;
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    self.transformingPullingIndexPath = nil;
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

    if (cell.frame.size.height > self.pullingCommitHeight * 2) {
        [self.filterView removeFromSuperview];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
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
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.contentView.frame];
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
    CGFloat alpha = 1 - (gestureRecognizer.translationInTableView.x / self.editingCommitLength);
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

    Event *event = [self.events.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];
    [[DataManager instance] deleteEvent:event];
    [self.events removeObject:event];
    self.isEventsInvalid = YES;

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
    return self.editingCommitLength;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger adjustedIndex = [self adjustedIndexForIndexPath:indexPath];
    Event *event = [self.events.filteredEvents objectAtIndex:adjustedIndex];
    self.state.activeEvent = event;

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[self adjustedRowCountForCount:self.events.filteredEvents.count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.transformingPullingIndexPath && self.transformingPullingIndexPath.row == indexPath.row) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pullingTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
        cell.textLabel.backgroundColor = [UIColor clearColor];

        if (cell.frame.size.height > self.pullingCommitHeight * 2) {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.text = @"Close";
            CGFloat alpha = 1 - (self.pullingCommitHeight * 2 / cell.frame.size.height);

            UIColor *backgroundColor = [UIColor colorWithRed:0.843f
                                                       green:0.306f
                                                        blue:0.314f
                                                       alpha:alpha];
            
            cell.contentView.backgroundColor = backgroundColor;
            self.tableView.tableHeaderView.backgroundColor = backgroundColor;
        } else {
            cell.textLabel.text = @"";

            UIColor *backgroundColor = [UIColor clearColor];
            cell.contentView.backgroundColor = backgroundColor;
            self.tableView.tableHeaderView.backgroundColor = backgroundColor;
        }

        return cell;
    } else {
        NSUInteger index = [self adjustedIndexForIndexPath:indexPath];
        Event *event = (Event *)[self.events.filteredEvents objectAtIndex:index];

        EventTableViewCell *cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:eventTableViewCellIdentifier];
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.941 green:0.933 blue:0.925 alpha:1.000];

        // Tag
        NSString *tagName = event.inTag ? event.inTag.name : @"-- --";
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

- (NSUInteger)adjustedIndexForIndexPath:(NSIndexPath *)indexPath {
    NSUInteger pullingRow = self.transformingPullingIndexPath ? 1 : 0;

    return (NSUInteger)indexPath.row - pullingRow;
}

- (NSUInteger)adjustedRowCountForCount:(NSUInteger)count {
    NSUInteger pullingRow = self.transformingPullingIndexPath ? 1 : 0;

    return count + pullingRow;
}

- (NSIndexPath *)adjustedIndexPathForIndex:(NSUInteger)index {
    NSUInteger pullingRow = self.transformingPullingIndexPath ? 1 : 0;

    return [NSIndexPath indexPathForRow:(NSInteger)(index + pullingRow) inSection:0];
}

- (void)objectsDidChange:(NSNotification *)note {
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *deletedObjects  = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *updatedObjects  = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

    // ========
    // = Tags =
    // ========
    NSSet *updatedTags = [updatedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }];

    NSSet *insertedTags = [insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }];

    [self.tags addObjectsFromArray:[insertedTags allObjects]];

    NSSet *deletedTags = [deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }];

    [self.tags removeObjectsInArray:[deletedTags allObjects]];

    if (updatedTags.count > 0 || insertedTags.count > 0 || deletedTags.count > 0) {
        self.isTagsInvalid = YES;
    }

    if ([deletedTags intersectsSet:self.state.eventsFilter]) {
        self.isEventsInvalid = YES;
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

    self.isEventsInvalid = YES;

    [self.tableView reloadData];

    NSUInteger index = [self.events.filteredEvents indexOfObject:self.state.activeEvent];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [self adjustedIndexPathForIndex:index];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)initFilterView {
    self.filterViewButtons = [NSMutableArray array];

    self.filterView.showsHorizontalScrollIndicator = NO;
    self.filterView.backgroundColor = [UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:0.90];

    UIColor *colorOne = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:0.3f];
    UIColor *colorTwo = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:1];

    NSArray *colors = @[(id)colorOne.CGColor, (id)colorTwo.CGColor, (id)colorTwo.CGColor, (id)colorOne.CGColor];

    NSArray *locations = @[@0.0, @0.4, @0.6, @1.0];

    CAGradientLayer *tick = [CAGradientLayer layer];
    tick.colors = colors;
    tick.locations = locations;
    tick.startPoint = CGPointMake(0, 0.5);
    tick.endPoint = CGPointMake(1.0, 0.5);

    tick.bounds      = CGRectMake(0, 0, self.filterView.layer.bounds.size.width, 1);
    CGPoint position = self.filterView.layer.position;
    position.y += 15;
    tick.position    = position;
    tick.anchorPoint = self.filterView.layer.anchorPoint;

    [self.filterView.layer addSublayer:tick];
}

- (void)setupFilterView {
    // Our bumper for the added height
    if (self.isFilterViewVisible) {
        if (!self.tableView.tableHeaderView) {
            UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
            tableHeaderView.backgroundColor = [UIColor clearColor];
            [self.tableView setTableHeaderView:tableHeaderView];
        }
    } else {
        self.tableView.tableHeaderView = nil;
    }

    // Remove all the old subviews and recreate them, lazy option
    for (id subView in self.filterViewButtons) {
        [subView removeFromSuperview];
    }

    [self.filterViewButtons removeAllObjects];

    // define number and size of elements
    NSUInteger numElements = self.tags.count;
    CGSize elementSize = CGSizeMake(120, self.filterView.frame.size.height);

    // add elements
    for (NSUInteger i = 0; i < numElements; i++) {
        Tag *tag = [self.tags objectAtIndex:i];

        TagButton* tagButton = [TagButton buttonWithType:UIButtonTypeCustom];
        tagButton.tagObject = tag;
        [tagButton addTarget:self action:@selector(touchUpInsideTagFilterButton:forEvent:) forControlEvents:UIControlEventTouchUpInside];

        //tagButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        tagButton.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:15];
        tagButton.titleLabel.backgroundColor = [UIColor clearColor];

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
    
    self.isTagsInvalid = NO;
}

- (void)animateBounceOnLayer:(CALayer *)layer fromPoint:(CGPoint)from toPoint:(CGPoint)to withDuration:(CFTimeInterval)duration completion:(void (^)(BOOL finished))completion{
    static NSString *keyPath = @"position";

	SKBounceAnimation *positionAnimation = [SKBounceAnimation animationWithKeyPath:keyPath];
	positionAnimation.fromValue = [NSValue valueWithCGPoint:from];
	positionAnimation.toValue = [NSValue valueWithCGPoint:to];
	positionAnimation.duration = duration;
	positionAnimation.numberOfBounces = 4;
    positionAnimation.completion = completion;

	[layer addAnimation:positionAnimation forKey:keyPath];
	[layer setValue:[NSValue valueWithCGPoint:to] forKeyPath:keyPath];
}

@end