//
//  EventGroupsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupsTableViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "Event.h"
#import "EventGroups.h"
#import "DataRepository.h"
#import "TagButton.h"
#import "EventGroupTableViewCell.h"
#import "Global.h"
#import "Tags.h"

@interface EventGroupsTableViewController ()

@property (nonatomic) NSMutableArray *filterViewButtons;

@property (nonatomic) EventGroups *eventGroups;
@property (nonatomic) BOOL isEventGroupsInvalid;

@property (nonatomic) Tags *tags;
@property (nonatomic) BOOL isTagsInvalid;
@property (nonatomic, readonly) BOOL isFilterViewVisible;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;

@property (nonatomic) UIState *state;

@end

@implementation EventGroupsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.calendar                    = [Global instance].calendar;
    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.standaloneWeekdaySymbols    = [[NSDateFormatter new] standaloneWeekdaySymbols];

    self.state = [DataRepository instance].state;

    self.tags          = [DataRepository instance].tags;
    self.isTagsInvalid = YES;

    [self initFilterView];

    self.eventGroups = [[EventGroups alloc] initWithEvents:[DataRepository instance].events
                                               withFilters:self.state.eventGroupsFilter];
    self.isEventGroupsInvalid = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(objectsDidChange:)
                                                 name:kDataManagerObjectsDidChangeNotification
                                               object:[DataRepository instance]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isTagsInvalid) {
        [self updateFilterView];
    }

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    CGFloat y    = self.isFilterViewVisible ? 0 : -30;
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

#pragma mark -
#pragma mark Public properties

- (EventGroups *)eventGroups {
    if (self.isEventGroupsInvalid) {
        _eventGroups.filters      = self.state.eventGroupsFilter;
        self.isEventGroupsInvalid = NO;
    }

    return _eventGroups;
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
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[self.eventGroups filteredCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"EventGroupTableViewCell";

    EventGroup *eventGroup = [self.eventGroups filteredObjectAtIndex:(NSUInteger)indexPath.row];

    EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    NSDateComponents *components = eventGroup.filteredEventsDateComponents;

    cell.hours.text   = [NSString stringWithFormat:@"%02d", components.hour];
    cell.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];

    static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
    components = [self.calendar components:unitFlags fromDate:eventGroup.groupDate];

    cell.day.text     = [NSString stringWithFormat:@"%02d", components.day];
    cell.year.text    = [NSString stringWithFormat:@"%04d", components.year];
    cell.month.text   = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    cell.weekDay.text = [[self.standaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString];

    return cell;
}

#pragma mark -
#pragma mark Private methods

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

- (void)updateFilterView {
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

        //tagButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        tagButton.titleLabel.font            = [UIFont fontWithName:@"Futura-Medium" size:15];
        tagButton.titleLabel.backgroundColor = [UIColor clearColor];

        tagButton.backgroundColor = [UIColor clearColor];

        [tagButton setTitleColor:[UIColor colorWithRed:0.333f green:0.333f blue:0.333f alpha:1] forState:UIControlStateNormal];
        [tagButton setTitle:[tag.name uppercaseString] forState:UIControlStateNormal];

        // setup frames to appear besides each other in the slider
        CGFloat elementX = elementSize.width * i;
        tagButton.frame = CGRectMake(elementX, 0, elementSize.width, elementSize.height);

        if ([self.state.eventGroupsFilter containsObject:tag]) {
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

- (void)touchUpInsideTagFilterButton:(TagButton *)sender forEvent:(UIEvent *)event {
    if ([self.state.eventGroupsFilter containsObject:sender.tagObject]) {
        [self.state removeEventGroupsFilterObject:sender.tagObject];

        sender.selected = NO;
    } else {
        [self.state addEventGroupsFilterObject:sender.tagObject];

        sender.selected = YES;
    }

    self.isEventGroupsInvalid = YES;

    [self.tableView reloadData];
}

- (void)objectsDidChange:(NSNotification *)note {
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *deletedObjects  = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *updatedObjects  = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

    // ==========
    // = Events =
    // ==========

    // Updated Events
    // this can generate update, insert and delete changes
    NSSet *updatedEvents = [updatedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Event class]];
        }];

    NSSet *insertedEvents = [insertedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Event class]];
        }];

    NSSet *deletedEvents = [deletedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Event class]];
        }];

    for (Event *event in updatedEvents) {
        [self.eventGroups updateEvent:event];
    }

    for (Event *event in insertedEvents) {
        [self.eventGroups addEvent:event];
    }

    for (Event *event in deletedEvents) {
        [self.eventGroups removeEvent:event];
    }

    if (updatedEvents.count > 0 || insertedEvents.count > 0 || deletedEvents.count > 0) {
        self.isEventGroupsInvalid = YES;
    }

    // ========
    // = Tags =
    // ========
    NSSet *updatedTags = [updatedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Tag class]];
        }];

    NSSet *insertedTags = [insertedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Tag class]];
        }];

    NSSet *deletedTags = [deletedObjects objectsPassingTest:^BOOL (id obj, BOOL *stop) {
            return [obj isKindOfClass:[Tag class]];
        }];

    if (updatedTags.count > 0 || insertedTags.count > 0 || deletedTags.count > 0) {
        self.isTagsInvalid = YES;
    }

    if ([deletedTags intersectsSet:self.state.eventGroupsFilter]) {
        self.isEventGroupsInvalid = YES;
    }
}

@end