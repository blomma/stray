//
//  EventGroupsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroups.h"
#import "EventGroupsTableViewController.h"
#import "UITableView+Change.h"
#import "DataManager.h"
#import "Change.h"
#import "TagButton.h"
#import "EventGroupTableViewCell.h"
#import "Global.h"
#import "Tags.h"

@interface EventGroupsTableViewController ()

@property (nonatomic) NSMutableArray *tagViewSubViews;

@property (nonatomic) EventGroups *eventGroups;
@property (nonatomic) BOOL doesEventGroupsRequireUpdate;

@property (nonatomic) NSMutableArray *tags;
@property (nonatomic) BOOL doesTagsRequireUpdate;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;

@property (nonatomic) UIState *state;

@end

@implementation EventGroupsTableViewController

#pragma mark -
#pragma mark Private Properties

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    self.calendar = [Global instance].calendar;
    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.standaloneWeekdaySymbols = [[NSDateFormatter new] standaloneWeekdaySymbols];

    self.tagViewSubViews = [NSMutableArray array];
    self.tags = [NSMutableArray array];
    self.doesTagsRequireUpdate = YES;

    self.state = [DataManager instance].state;
    self.eventGroups = [[EventGroups alloc] initWithEvents:[DataManager instance].events
                                                    withFilters:self.state.eventGroupsFilter];
    self.doesEventGroupsRequireUpdate = YES;

    self.tagView.backgroundColor = [UIColor colorWithWhite:0.075 alpha:0.65];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(objectsDidChange:)
	                                             name:kDataManagerObjectsDidChangeNotification
	                                           object:[DataManager instance]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    DLog(NSStringFromSelector(_cmd));

    if (self.doesTagsRequireUpdate) {
        [self updateTagsView];
    }

    if (self.doesEventGroupsRequireUpdate) {
        [self updateEventGroups];
    } else {
        [self refreshVisibleRows];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 && self.tags.count > 0 ? 144 : 100;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DLog(@"eventGroups count %u", self.eventGroups.count);
    return (NSInteger)self.eventGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventGroupTableViewCell";

    EventGroup *eventGroup = [self.eventGroups objectAtIndex:(NSUInteger)indexPath.row];

	EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	NSDateComponents *components = eventGroup.filteredEventsDateComponents;

	cell.hours.text   = [NSString stringWithFormat:@"%02d", components.hour];
	cell.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];

	static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
	components = [self.calendar components:unitFlags fromDate:eventGroup.groupDate];

	cell.day.text      = [NSString stringWithFormat:@"%02d", components.day];
	cell.year.text     = [NSString stringWithFormat:@"%04d", components.year];
	cell.month.text    = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    cell.weekDay.text  = [[self.standaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString];
    
	return cell;
}

#pragma mark -
#pragma mark Private methods

- (void)updateEventGroups {
    self.eventGroups.filters = self.state.eventGroupsFilter;
    [self.tableView reloadData];
}

- (void)updateTagsView {
    DLog(NSStringFromSelector(_cmd));

    [self.tags removeAllObjects];
    [self.tags addObjectsFromArray:[[[DataManager instance] tags]
                                    sortedArrayWithOptions:NSSortConcurrent
                                    usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                        if ([obj1 sortIndex].integerValue < [obj2 sortIndex].integerValue) {
                                            return NSOrderedAscending;
                                        } else if ([obj1 sortIndex].integerValue > [obj2 sortIndex].integerValue) {
                                            return NSOrderedDescending;
                                        } else {
                                            return NSOrderedSame;
                                        }
                                    }]];

    // Remove all the old subviews and recreate them, lazy option
    for (id subView in self.tagViewSubViews) {
        [subView removeFromSuperview];
    }

    [self.tagViewSubViews removeAllObjects];

    // define number and size of elements
    NSUInteger numElements = self.tags.count;
    CGSize elementSize = CGSizeMake(120, self.tagView.frame.size.height);

    // add elements
    for (NSUInteger i = 0; i < numElements; i++) {
        Tag *tag = [self.tags objectAtIndex:i];

        TagButton* subview = [TagButton buttonWithType:UIButtonTypeCustom];
        subview.tagObject = tag;
        [subview addTarget:self action:@selector(tagTouchUp:forEvent:) forControlEvents:UIControlEventTouchUpInside];

        subview.titleLabel.textColor = [UIColor whiteColor];
        subview.titleLabel.textAlignment = NSTextAlignmentCenter;
        subview.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:15];
        subview.titleLabel.backgroundColor = [UIColor clearColor];

        UIColor *backgroundColor = [UIColor clearColor];
        if ([self.state.eventGroupsFilter containsObject:tag]) {
            backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.000];
        }

        subview.backgroundColor = backgroundColor;

        [subview setTitle:[tag.name uppercaseString] forState:UIControlStateNormal];
        // select a differing red value so that we can distinguish our added subviews
        //        float redValue = (1.0f / numElements) * i;
        //        subview.backgroundColor = [UIColor colorWithRed:redValue green:0 blue:0  alpha:1.0];

        // setup frames to appear besides each other in the slider
        CGFloat elementX = elementSize.width * i;
        subview.frame = CGRectMake(elementX, 0, elementSize.width, elementSize.height);

        [self.tagViewSubViews addObject:subview];

        // add the subview
        [self.tagView addSubview:subview];
    }

    if (self.tags.count == 0) {
        self.tagView.hidden = YES;
    } else {
        self.tagView.hidden = NO;
    }

    // set the size of the scrollview's content
    self.tagView.contentSize = CGSizeMake(numElements * elementSize.width, elementSize.height);

    self.doesTagsRequireUpdate = NO;
}

- (void)tagTouchUp:(TagButton *)sender forEvent:(UIEvent *)event {
    DLog(NSStringFromSelector(_cmd));
    if ([self.state.eventGroupsFilter containsObject:sender.tagObject]) {
        [self.state removeEventGroupsFilterObject:sender.tagObject];

        [UIView animateWithDuration:0.2 animations:^{
            sender.backgroundColor = [UIColor clearColor];
        }];
    } else {
        [self.state addEventGroupsFilterObject:sender.tagObject];

        [UIView animateWithDuration:0.2 animations:^{
            sender.backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.000];
        }];
    }

    [self updateEventGroups];
}

- (void)objectsDidChange:(NSNotification *)note {
    DLog(NSStringFromSelector(_cmd));
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *deletedObjects  = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *updatedObjects  = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

    // ==========
    // = Events =
    // ==========

    // Updated Events
    // this can generate update, insert and delete changes
    NSSet *updatedEvents = [updatedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }];

    NSSet *insertedEvents = [insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }];

    NSSet *deletedEvents = [deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
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
        self.doesEventGroupsRequireUpdate = YES;
    }

    // ==========
    // = Tags =
    // ==========
    NSSet *updatedTags = [updatedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }];

    NSSet *insertedTags = [insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }];

    NSSet *deletedTags = [deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }];

    if (updatedTags.count > 0 || insertedTags.count > 0 || deletedTags.count > 0) {
        self.doesTagsRequireUpdate = YES;
    }

    if ([deletedObjects intersectsSet:self.state.eventGroupsFilter]) {
        self.doesEventGroupsRequireUpdate = YES;
    }
}

- (void)refreshVisibleRows {
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];

    if (visibleRows.count == 0) {
        [self.tableView reloadData];
        return;
    }

    NSMutableSet *changes = [NSMutableArray array];
    for (NSIndexPath *path in visibleRows) {
        Change *change = [Change new];
        change.type = ChangeUpdate;
        change.index = path.row;

        [changes addObject:change];
    }

    [self.tableView updateWithChanges:changes];
}

@end
