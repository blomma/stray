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
#import "TagFilterButton.h"
#import "EventsGroupedByDateTableViewCell.h"
#import "State.h"
#import "Tag.h"
#import "NSDate+Utilities.h"

@interface EventsGroupedByDateViewController ()

@property (nonatomic) NSMutableArray *filterViewButtons;
@property (nonatomic) BOOL isFilterViewInvalid;

@property (nonatomic) EventsGroupedByDate *eventGroups;
@property (nonatomic) BOOL isEventGroupsInvalid;
@property (nonatomic) BOOL isEventGroupsViewInvalid;

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;
@property (nonatomic) id managedContextObserver;
@property (nonatomic) id foregroundObserver;

@end

@implementation EventsGroupedByDateViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.standaloneWeekdaySymbols    = [[NSDateFormatter new] standaloneWeekdaySymbols];

    [self initFilterView];

    NSArray *events = [Event MR_findAllSortedBy:@"startDate" ascending:YES];
    self.eventGroups = [[EventsGroupedByDate alloc] initWithEvents:events
                                                       withFilters:[State instance].eventsGroupedByDateFilter];
    self.isEventGroupsInvalid = YES;
    self.isEventGroupsViewInvalid = YES;
    self.isFilterViewInvalid = YES;

    __weak typeof(self) weakSelf = self;
    self.managedContextObserver = [[NSNotificationCenter defaultCenter]
                     addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                     object:[NSManagedObjectContext MR_defaultContext]
                     queue:nil
                     usingBlock:^(NSNotification *note) {
                         NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
                         NSSet *deletedObjects  = [[note userInfo] objectForKey:NSDeletedObjectsKey];
                         NSSet *updatedObjects  = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

                         // ==========
                         // = Events =
                         // ==========
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
                             [weakSelf.eventGroups updateEvent:event];
                         }

                         for (Event *event in insertedEvents) {
                             [weakSelf.eventGroups addEvent:event];
                         }

                         for (Event *event in deletedEvents) {
                             [weakSelf.eventGroups removeEvent:event];
                         }

                         if (updatedEvents.count > 0 || insertedEvents.count > 0 || deletedEvents.count > 0) {
                             weakSelf.isEventGroupsInvalid = YES;
                             weakSelf.isEventGroupsViewInvalid = YES;
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

                         if (updatedTags.count > 0 || insertedTags.count > 0) {
                             weakSelf.isFilterViewInvalid = YES;
                         }

                         for (Tag *tag in deletedTags) {
                             NSUInteger index = [weakSelf.filterViewButtons indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
                                 NSString *guid = ((TagFilterButton *)obj).tagGuid;
                                 if ([guid isEqualToString:tag.guid]) {
                                     *stop = YES;
                                     return YES;
                                 }
                                 
                                 return NO;
                             }];
                             
                             if (index != NSNotFound) {
                                 weakSelf.isEventGroupsInvalid = YES;
                                 weakSelf.isEventGroupsViewInvalid = YES;
                                 weakSelf.isFilterViewInvalid = YES;
                                 
                                 [[State instance].eventsGroupedByStartDateFilter removeObject:tag.guid];
                             }
                         }
                     }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __weak typeof(self) weakSelf = self;
    self.foregroundObserver = [[NSNotificationCenter defaultCenter]
                               addObserverForName:UIApplicationWillEnterForegroundNotification
                               object:nil
                               queue:nil
                               usingBlock:^(NSNotification *note) {
                                   [weakSelf.tableView reloadData];
                               }];

    if (self.isFilterViewInvalid) {
        [self setupFilterView];
    }

    if (self.isEventGroupsViewInvalid) {
        [self.tableView reloadData];

        self.isEventGroupsViewInvalid = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self.foregroundObserver];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.managedContextObserver];
}

#pragma mark -
#pragma mark Public properties

- (EventsGroupedByDate *)eventGroups {
    if (self.isEventGroupsInvalid) {
        _eventGroups.filters      = [State instance].eventsGroupedByDateFilter;
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
    return (NSInteger)self.eventGroups.filteredEventGroupCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"EventsGroupedByDateTableViewCell";

    EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)indexPath.row];

    EventsGroupedByDateTableViewCell *cell = (EventsGroupedByDateTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    NSDateComponents *components = eventGroup.filteredEventsDateComponents;

    cell.hours.text   = [NSString stringWithFormat:@"%02d", components.hour];
    cell.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];

    static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
    components = [[NSDate calendar] components:unitFlags fromDate:eventGroup.groupDate];

    cell.day.text     = [NSString stringWithFormat:@"%02d", components.day];
    cell.year.text    = [NSString stringWithFormat:@"%04d", components.year];
    cell.month.text   = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    cell.weekDay.text = [[self.standaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString];

    return cell;
}

#pragma mark -
#pragma mark Private methods

- (void)touchUpInsideTagFilterButton:(TagFilterButton *)sender forEvent:(UIEvent *)event {
    if ([[State instance].eventsGroupedByDateFilter containsObject:sender.tagGuid]) {
        [[State instance].eventsGroupedByDateFilter removeObject:sender.tagGuid];

        sender.selected = NO;
    } else {
        [[State instance].eventsGroupedByDateFilter addObject:sender.tagGuid];

        sender.selected = YES;
    }

    self.isEventGroupsInvalid = YES;

    [self.tableView reloadData];
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

    NSArray *tags = [Tag MR_findAllSortedBy:@"sortIndex" ascending:YES];

    // add elements
    for (NSUInteger i = 0; i < tags.count; i++) {
        Tag *tag = [tags objectAtIndex:i];

        // Only show tags that have a name set
        if (tag.name) {
            TagFilterButton *button = [[TagFilterButton alloc] init];
            button.tagGuid = tag.guid;
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

            if ([[State instance].eventsGroupedByDateFilter containsObject:tag.guid]) {
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

    self.isFilterViewInvalid = NO;
}

@end
