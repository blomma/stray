//
//  EventGroupViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupViewController.h"
#import "EventGroupTableViewDataSource.h"
#import "Event.h"
#import "EventTableViewCell.h"
#import "Change.h"
#import "UITableView+Change.h"
#import "DataManager.h"

@interface EventGroupViewController ()

@property (nonatomic) EventGroupTableViewDataSource *dataSource;
@property (nonatomic) Event *selectedEvent;

@end

@implementation EventGroupViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataSource = [[EventGroupTableViewDataSource alloc] init];
    self.dataSource.eventGroup = self.eventGroup;
    self.eventGroupTableView.dataSource = self.dataSource;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:kDataManagerDidSaveNotification
	                                           object:[DataManager instance]];

    NSIndexPath *path = [NSIndexPath indexPathForRow:0
                                            inSection:0];

    [self.eventGroupTableView selectRowAtIndexPath:path
                                          animated:YES
                                    scrollPosition:UITableViewScrollPositionTop];

    [self didSelectRowAtIndexPath:path];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kDataManagerDidSaveNotification
                                                  object:[DataManager instance]];

    self.selectedEvent = nil;
    self.eventGroup = nil;
}

#pragma mark -
#pragma mark Private properties

- (void)setSelectedEvent:(Event *)selectedEvent {
    if (self.selectedEvent) {
        [self.eventTimerControl removeObserver:self
                                    forKeyPath:@"startDate"
                                       context:NULL];

        [self.eventTimerControl removeObserver:self
                                    forKeyPath:@"stopDate"
                                       context:NULL];

        [self.eventTimerControl removeObserver:self
                                    forKeyPath:@"isTransforming"
                                       context:NULL];
    }

    _selectedEvent = selectedEvent;

    if (selectedEvent) {
        [self.eventTimerControl addObserver:self
                                 forKeyPath:@"startDate"
                                    options:NSKeyValueObservingOptionNew
                                    context:NULL];

        [self.eventTimerControl addObserver:self
                                 forKeyPath:@"stopDate"
                                    options:NSKeyValueObservingOptionNew
                                    context:NULL];

        [self.eventTimerControl addObserver:self
                                 forKeyPath:@"isTransforming"
                                    options:NSKeyValueObservingOptionNew
                                    context:NULL];
    }
}

#pragma mark -
#pragma mark Public methods

- (IBAction)closeModal:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark Private methods

- (void)dataModelDidSave:(NSNotification *)note {
    // Was this the last event in the group, if so close the window
    if (self.eventGroup.count == 0) {
        [self dismissViewControllerAnimated:YES completion:NULL];
        return;
    }

	NSSet *eventChangeObjects = [[note userInfo] objectForKey:kEventChangesKey];
    NSArray *changes = [[eventChangeObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        Change *change = (Change *)obj;
        return [change.parentObject isEqual:self.eventGroup];
    }] allObjects];

    [self.eventGroupTableView updateWithChanges:changes];

    // Is our selected event still with us
    NSUInteger index = [self.eventGroup.events indexOfObject:self.selectedEvent];
    if (index == NSNotFound) {
        self.selectedEvent = nil;
        [self.eventTimerControl reset];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.selectedEvent.startDate = date;

        [self.dataSource tableView:self.eventGroupTableView refreshCellForEvent:self.selectedEvent];
	} else if ([keyPath isEqualToString:@"stopDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.selectedEvent.stopDate = date;

        [self.dataSource tableView:self.eventGroupTableView refreshCellForEvent:self.selectedEvent];
    } else if ([keyPath isEqualToString:@"isTransforming"]) {
        EventTimerTransformingEnum isTransforming = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (isTransforming == EventTimerStartDateTransformingStop) {
            [[CoreDataManager instance] saveContext];
        } else if (isTransforming == EventTimerStopDateTransformingStop) {
            [[CoreDataManager instance] saveContext];
        }
    }
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Event *event = [self.dataSource eventAtIndex:(NSUInteger)indexPath.row];
    self.selectedEvent = event;

    [self.eventTimerControl startWithEvent:event];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self didSelectRowAtIndexPath:indexPath];
}

@end