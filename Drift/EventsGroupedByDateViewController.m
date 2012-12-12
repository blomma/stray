//
//  EventsGroupedByDateViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsGroupedByDateViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "Event.h"
#import "EventsGroupedByDate.h"
#import "DataRepository.h"
#import "TagFilterButton.h"
#import "EventsGroupedByDateTableViewCell.h"
#import "Global.h"
#import "Tags.h"

@interface EventsGroupedByDateViewController ()

@property (nonatomic) NSMutableArray *filterViewButtons;

@property (nonatomic) EventsGroupedByDate *eventGroups;
@property (nonatomic) BOOL isEventGroupsInvalid;

@property (nonatomic) Tags *tags;
@property (nonatomic) BOOL isTagsInvalid;
@property (nonatomic, readonly) BOOL isFilterViewVisible;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;

@property (nonatomic, weak) State *state;

@end

@implementation EventsGroupedByDateViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.calendar                    = [Global instance].calendar;
    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.standaloneWeekdaySymbols    = [[NSDateFormatter new] standaloneWeekdaySymbols];

    self.state = [DataRepository instance].state;

    self.tags          = [DataRepository instance].tags;
    self.isTagsInvalid = YES;

    [self initFilterView];

    self.eventGroups = [[EventsGroupedByDate alloc] initWithEvents:[DataRepository instance].events
                                                       withFilters:self.state.eventGroupsFilter];
    self.isEventGroupsInvalid = YES;

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
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

#pragma mark -
#pragma mark Private properties

- (void)showInfoHintView:(UIView *)view {
    [self performSegueWithIdentifier:@"segueToInfoHintViewFromEventGroups" sender:self];
}

- (BOOL)isFilterViewVisible {
    return self.tags.count > 0;
}

#pragma mark -
#pragma mark Public properties

- (EventsGroupedByDate *)eventGroups {
    if (self.isEventGroupsInvalid) {
        _eventGroups.filters      = self.state.eventGroupsFilter;
        self.isEventGroupsInvalid = NO;
    }

    return _eventGroups;
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
    static NSString *cellIdentifier = @"EventsGroupedByDateTableViewCell";

    EventGroup *eventGroup = [self.eventGroups filteredObjectAtIndex:(NSUInteger)indexPath.row];

    EventsGroupedByDateTableViewCell *cell = (EventsGroupedByDateTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

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

        // Only show tags that have a name set
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

            if ([self.state.eventGroupsFilter containsObject:tag]) {
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

- (void)touchUpInsideTagFilterButton:(TagFilterButton *)sender forEvent:(UIEvent *)event {
    if ([self.state.eventGroupsFilter containsObject:sender.tagObject]) {
        [self.state.eventGroupsFilter removeObject:sender.tagObject];

        sender.selected = NO;
    } else {
        [self.state.eventGroupsFilter addObject:sender.tagObject];

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

- (void)appWillEnterForegroundNotification:(NSNotification *)note {
    [self.tableView reloadData];
}

@end