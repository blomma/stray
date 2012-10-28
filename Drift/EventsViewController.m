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
#import "Events.h"
#import "TagButton.h"
#import "Tags.h"

static NSInteger kEditCommitLength = 120;
static NSInteger kAddingCommitHeight = 60;

static NSString *pullDownTableViewCellIdentifier = @"pullDownTableViewCellIdentifier";

@interface EventsViewController ()<TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGesturePullingRowDelegate, EventTableViewCellDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSMutableArray *filterViewButtons;

@property (nonatomic) Tags *tags;
@property (nonatomic) BOOL isTagsInvalid;

@property (nonatomic) UIState *state;

@property (nonatomic) Events *events;
@property (nonatomic) BOOL isEventsInvalid;

@property (nonatomic) NSIndexPath *transformingPullingIndexPath;

@end

@implementation EventsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.calendar = [Global instance].calendar;
    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];

    self.state = [DataManager instance].state;

    self.tags = [[Tags alloc] initWithTags:[[DataManager instance] tags]];
    self.isTagsInvalid = YES;

    self.filterView.showsHorizontalScrollIndicator = NO;
    self.filterView.backgroundColor = [UIColor colorWithWhite:0.075 alpha:0.45];
    self.filterViewButtons = [NSMutableArray array];

    self.events = [[Events alloc] initWithEvents:[DataManager instance].events];
    self.isEventsInvalid = YES;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:pullDownTableViewCellIdentifier];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(objectsDidChange:)
	                                             name:kDataManagerObjectsDidChangeNotification
	                                           object:[DataManager instance]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvents"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Event *event = [self.events.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];

        if ([[segue destinationViewController] respondsToSelector:@selector(event)]) {
            [[segue destinationViewController] setEvent:event];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isTagsInvalid) {
        [self updateTagsView];
    }

    [self.tableView reloadData];
}

- (Events *)events {
    if (self.isEventsInvalid) {
        _events.filters = self.state.eventsFilter;
        self.isEventsInvalid = NO;
    }

    return _events;
}

#pragma mark -
#pragma mark EventTableViewCellDelegate

- (void)cell:(UITableViewCell *)cell tappedTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
   [self performSegueWithIdentifier:@"segueToTagsFromEvents" sender:cell];
}

#pragma mark -
#pragma mark TransformableTableViewGesturePullingRowDelegate

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return kAddingCommitHeight;
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

    if (cell.frame.size.height > kAddingCommitHeight * 2) {
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

    Event *event = [self.events.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];
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
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Event *event = [self.events.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];
    self.state.activeEvent = event;

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.transformingPullingIndexPath ? (NSInteger)self.events.filteredEvents.count + 1 : (NSInteger)self.events.filteredEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventTableViewCell";

    if (self.transformingPullingIndexPath && self.transformingPullingIndexPath.row == indexPath.row) {
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
        NSUInteger index = self.transformingPullingIndexPath ? (NSUInteger)indexPath.row - 1 : (NSUInteger)indexPath.row;
        Event *event = (Event *)[self.events.filteredEvents objectAtIndex:index];

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
}

- (void)updateTagsView {
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

        tagButton.titleLabel.textColor = [UIColor whiteColor];
        tagButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        tagButton.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:15];
        tagButton.titleLabel.backgroundColor = [UIColor clearColor];

        tagButton.backgroundColor = [UIColor clearColor];

        [tagButton setTitle:[tag.name uppercaseString] forState:UIControlStateNormal];
        // select a differing red value so that we can distinguish our added subviews
        //        float redValue = (1.0f / numElements) * i;
        //        subview.backgroundColor = [UIColor colorWithRed:redValue green:0 blue:0  alpha:1.0];

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

	[layer addAnimation:positionAnimation forKey:@"someKey2"];
	[layer setValue:[NSValue valueWithCGPoint:to] forKeyPath:keyPath];
}

@end