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

@interface EventGroupsTableViewController ()

@property (nonatomic) NSMutableArray *tagViewSubViews;
@property (nonatomic) TagButton *selectedTagButton;
@property (nonatomic) Tag *selectedTag;

@property (nonatomic) EventGroups *eventGroups;

@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;

@property (nonatomic) UIState *state;

@end

@implementation EventGroupsTableViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    DLog(NSStringFromSelector(_cmd));

    self.state = [DataManager instance].state;
    self.selectedTag = self.state.activeTagFilter;

    self.eventGroups = [[EventGroups alloc] initWithEvents:[DataManager instance].events filter:self.selectedTag];

    self.calendar = [NSCalendar currentCalendar];
    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.standaloneWeekdaySymbols = [[NSDateFormatter new] standaloneWeekdaySymbols];

    self.tagViewSubViews = [NSMutableArray new];
    self.tagView.backgroundColor = [UIColor colorWithWhite:0.075 alpha:0.65];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(objectsDidChange:)
	                                             name:kDataManagerObjectsDidChangeNotification
	                                           object:[DataManager instance]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    DLog(NSStringFromSelector(_cmd));

    [self addTagsToSlider:self.tagView];
    [self refreshVisibleRows];
}

- (void)tagTouchUp:(TagButton *)sender forEvent:(UIEvent *)event {
    // Deslect the previous one
    [UIView animateWithDuration:0.2 animations:^{
        self.selectedTagButton.backgroundColor = [UIColor clearColor];
    }];

    self.selectedTagButton = [self.selectedTagButton isEqual:sender] ? nil : sender;
    self.selectedTag = self.selectedTagButton.tagObject;

    if (self.selectedTagButton) {
        [UIView animateWithDuration:0.2 animations:^{
            self.selectedTagButton.backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.000];
        }];
    }

    self.state.activeTagFilter = self.selectedTag;

    // TODO: At the moment we ignore the changes since they dont work for
    // this scenario, instead we do a full reload
    [self.eventGroups filterOnTag:self.selectedTag];

    [self.tableView reloadData];
}

- (void)addTagsToSlider:(UIScrollView*)slider {
    NSArray *tags = [DataManager instance].tags;

    // Remove all the old subviews and recreate them, lazy option
    for (id subView in self.tagViewSubViews) {
        [subView removeFromSuperview];
    }

    [self.tagViewSubViews removeAllObjects];
    self.selectedTagButton = nil;

    // define number and size of elements
    NSUInteger numElements = tags.count;
    CGSize elementSize = CGSizeMake(120, slider.frame.size.height);

    // add elements
    for (NSUInteger i = 0; i < numElements; i++) {
        Tag *tag = [tags objectAtIndex:i];

        TagButton* subview = [TagButton buttonWithType:UIButtonTypeCustom];
        subview.tagObject = tag;
        [subview addTarget:self action:@selector(tagTouchUp:forEvent:) forControlEvents:UIControlEventTouchUpInside];

        subview.titleLabel.textColor = [UIColor whiteColor];
        subview.titleLabel.textAlignment = NSTextAlignmentCenter;
        subview.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:15];
        subview.titleLabel.backgroundColor = [UIColor clearColor];

        UIColor *backgroundColor = [UIColor clearColor];
        if ([tag isEqual:self.selectedTag]) {
            self.selectedTagButton = subview;
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
        [slider addSubview:subview];
    }

    // set the size of the scrollview's content
    slider.contentSize = CGSizeMake(numElements * elementSize.width, elementSize.height);

    DLog(@"%u", self.tagView.subviews.count);
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 ? 144 : 100;
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

	EventGroup *eventGroup = [self.eventGroups eventGroupAtIndex:(NSUInteger)indexPath.row];

	EventGroupTableViewCell *cell = (EventGroupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	NSDateComponents *components = eventGroup.timeActiveComponents;

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

- (void)objectsDidChange:(NSNotification *)note {
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

    DLog(@"insertedObjects %@", insertedObjects);
    DLog(@"deletedObjects %@", deletedObjects);
    DLog(@"updatedObjects %@", updatedObjects);

    // ==========
    // = Events =
    // ==========
    NSMutableSet *changes = [NSMutableSet set];

    // Updated Events
    // this can generate update, insert and delete changes
    NSSet *updatedEvents = [updatedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }];

    DLog(@"updatedEvents %@", updatedEvents);

    for (Event *event in updatedEvents) {
        [changes unionSet:[self.eventGroups updateEvent:event]];
    }

    // Inserted Events
    NSSet *insertedEvents = [insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }];

    DLog(@"insertedEvents %@", insertedEvents);

    for (Event *event in insertedEvents) {
        [changes unionSet:[self.eventGroups addEvent:event]];
    }

    // Deleted Events
    NSSet *deletedEvents = [deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Event class]];
    }];

    DLog(@"deletedEvents %@", deletedEvents);

    for (Event *event in deletedEvents) {
        [changes unionSet:[self.eventGroups removeEvent:event]];
    }

    // We are only interested in the changes affecting eventGroups
    NSSet *eventGroupChanges = [changes objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [[(Change *)obj object] isKindOfClass:[EventGroup class]];
    }];

    [self.tableView updateWithChanges:eventGroupChanges];
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
