//
//  EventGroupsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroup.h"
#import "EventGroups.h"
#import "EventGroupsTableViewController.h"
#import "EventGroupsTableViewDataSource.h"
#import "EventGroupViewController.h"
#import "NSManagedObject+ActiveRecord.h"
#import "Tag.h"
#import "UITableView+Change.h"
#import "DataManager.h"
#import "Change.h"
#import "TagButton.h"

@interface EventGroupsTableViewController ()

@property (nonatomic) EventGroupViewController *eventGroupViewController;
@property (nonatomic) EventGroupsTableViewDataSource *dataSource;
@property (nonatomic) NSMutableArray *tagViewSubViews;
@property (nonatomic) TagButton *selectedTagButton;
@property (nonatomic) Tag *selectedTag;

@end

@implementation EventGroupsTableViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    EventGroupsTableViewDataSource *dataSource = [EventGroupsTableViewDataSource new];

    self.dataSource = dataSource;
    self.tableView.dataSource = dataSource;

    self.tagViewSubViews = [NSMutableArray new];
    self.tagView.backgroundColor = [UIColor colorWithWhite:0.075 alpha:0.8];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:kDataManagerDidSaveNotification
	                                           object:[DataManager instance]];

	[[[DataManager instance] eventGroups] addObserver:self
                                           forKeyPath:@"existsActiveEventGroup"
                                              options:NSKeyValueObservingOptionNew
                                              context:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self refreshVisibleRows];
    [self addTagsToSlider:self.tagView];
}

- (void)tagTouchUp:(TagButton *)sender forEvent:(UIEvent *)event {
    EventGroups *groups = [[DataManager instance] eventGroups];

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

    // TODO: At the moment we ignore the changes since they dont work for
    // this scenario, instead we do a full reload
    [groups filterOnTag:self.selectedTagButton.tagObject];

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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [sender setSelected:NO animated:YES];

    EventGroupViewController *eventGroupViewController = [segue destinationViewController];
    EventGroup *eventGroup = [[[DataManager instance] eventGroups] eventGroupAtIndex:(NSUInteger)[self.tableView indexPathForSelectedRow].row];

    eventGroupViewController.eventGroup = eventGroup;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == 0 ? 144 : 100;
}

#pragma mark -
#pragma mark Private methods

- (void)dataModelDidSave:(NSNotification *)note {
    NSSet *changes = [[note userInfo] objectForKey:kEventGroupChangesKey];
    DLog(@"changes %@", changes);

    [self.tableView updateWithChanges:changes];
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
