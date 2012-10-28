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
#import "DataManager.h"
#import "TagButton.h"
#import "EventGroupTableViewCell.h"
#import "Global.h"
#import "Tags.h"

@interface EventGroupsTableViewController ()

@property (nonatomic) NSMutableArray *tagViewSubViews;

@property (nonatomic) EventGroups *eventGroups;
@property (nonatomic) BOOL isEventGroupsInvalid;

@property (nonatomic) Tags *tags;
@property (nonatomic) BOOL isTagsInvalid;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;

@property (nonatomic) UIState *state;

@end

@implementation EventGroupsTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];

    self.calendar = [Global instance].calendar;
    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.standaloneWeekdaySymbols = [[NSDateFormatter new] standaloneWeekdaySymbols];

    self.state = [DataManager instance].state;

    self.tags = [[Tags alloc] initWithTags:[[DataManager instance] tags]];
    self.isTagsInvalid = YES;

    self.tagView.showsHorizontalScrollIndicator = NO;
    self.tagView.backgroundColor = [UIColor colorWithWhite:0.075 alpha:0.45];
    self.tagViewSubViews = [NSMutableArray array];


    self.eventGroups = [[EventGroups alloc] initWithEvents:[DataManager instance].events
                                               withFilters:self.state.eventGroupsFilter];
    self.isEventGroupsInvalid = YES;

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(objectsDidChange:)
	                                             name:kDataManagerObjectsDidChangeNotification
	                                           object:[DataManager instance]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.isTagsInvalid) {
        [self updateTagsView];
    }

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    CGFloat y = self.tags.count == 0 ? -30 : 0;
    CGRect frame = CGRectMake(0, y, self.view.bounds.size.width, 30);

    [UIView animateWithDuration:0.3 animations:^{
        self.tagView.frame = frame;
    }];
}

#pragma mark -
#pragma mark Public properties

- (EventGroups *)eventGroups {
    if (self.isEventGroupsInvalid) {
        _eventGroups.filters = self.state.eventGroupsFilter;
        self.isEventGroupsInvalid = NO;
    }

    return _eventGroups;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 && self.tags.count > 0 ? 130 : 100;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.eventGroups.filteredEventGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventGroupTableViewCell";

    EventGroup *eventGroup = [self.eventGroups.filteredEventGroups objectAtIndex:(NSUInteger)indexPath.row];

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

- (void)updateTagsView {
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

        if ([self.state.eventGroupsFilter containsObject:tag]) {
            tagButton.selected = YES;
        }

        [self.tagViewSubViews addObject:tagButton];

        // add the subview
        [self.tagView addSubview:tagButton];
    }

    // set the size of the scrollview's content
    self.tagView.contentSize = CGSizeMake(numElements * elementSize.width, elementSize.height);

    self.isTagsInvalid = NO;
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
        self.isEventGroupsInvalid = YES;
    }

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

    if ([deletedTags intersectsSet:self.state.eventGroupsFilter]) {
        self.isEventGroupsInvalid = YES;
    }
}

@end
