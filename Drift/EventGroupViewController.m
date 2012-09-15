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
#import "EventDataManager.h"
#import "EventChange.h"
#import "EventTableViewCell.h"

@interface EventGroupViewController ()

@property (nonatomic) EventGroupTableViewDataSource *dataSource;
@property (nonatomic) Event *selectedEvent;
@property (nonatomic) EventTableViewCell *selectedCell;

@end

@implementation EventGroupViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataSource = [[EventGroupTableViewDataSource alloc] init];
    self.dataSource.eventGroup = self.eventGroup;
    self.eventGroupTableView.dataSource = self.dataSource;

	// Get notified of new things happening
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(handleDataModelChange:)
	                                             name:NSManagedObjectContextObjectsDidChangeNotification
	                                           object:[NSManagedObjectContext MR_defaultContext]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

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
#pragma mark Public properties

- (void)setEventGroup:(EventGroup *)eventGroup {
    if (self.eventGroup) {
        [self.eventGroup removeObserver:self
                             forKeyPath:@"changes"
                                context:NULL];
    }

    _eventGroup = eventGroup;

    if (eventGroup) {
        [self.eventGroup addObserver:self
                          forKeyPath:@"changes"
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

- (void)handleDataModelChange:(NSNotification *)note {
	NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    if (deletedObjects) {
        NSArray *deletedEvents = [deletedObjects allObjects];

        NSUInteger index = [deletedEvents indexOfObject:self.selectedEvent];

        if (index != NSNotFound) {
            self.selectedEvent = nil;
            [self.eventTimerControl reset];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.selectedEvent.startDate = date;

        [self.dataSource tableView:self.eventGroupTableView refreshCell:self.selectedCell];
	} else if ([keyPath isEqualToString:@"stopDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.selectedEvent.stopDate = date;

        [self.dataSource tableView:self.eventGroupTableView refreshCell:self.selectedCell];
    } else if ([keyPath isEqualToString:@"isTransforming"]) {
        EventTimerTransformingEnum isTransforming = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (isTransforming == EventTimerTransformingStartDateStart) {
        } else if (isTransforming == EventTimerTransformingStopDateStart) {
        } else if (isTransforming == EventTimerTransformingStartDateStop) {
            [[EventDataManager sharedManager] persistCurrentEvent];
        } else if (isTransforming == EventTimerTransformingStopDateStop) {
            [[EventDataManager sharedManager] persistCurrentEvent];
        }
    } else if ([keyPath isEqualToString:@"changes"]) {
		NSArray *changes = [change objectForKey:NSKeyValueChangeNewKey];

        [self updateTableViewWithChanges:changes];
    }
}

- (void)updateTableViewWithChanges:(NSArray *)changes {
    if (changes.count > 0) {
        NSMutableArray *insertIndexPaths = [NSMutableArray array];
        NSMutableArray *deleteIndexPaths = [NSMutableArray array];

        for (EventChange *eventChange in changes) {
            if ([eventChange.type isEqualToString:EventChangeDelete]) {
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventChange.index inSection:0]];
            } else if ([eventChange.type isEqualToString:EventChangeInsert]) {
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:(NSInteger)eventChange.index inSection:0]];
            }
        }

        [self.eventGroupTableView beginUpdates];

        [self.eventGroupTableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];
        [self.eventGroupTableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];

        [self.eventGroupTableView endUpdates];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedCell = (EventTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];

    Event *event = [self.dataSource eventAtIndex:(NSUInteger)indexPath.row];
    self.selectedEvent = event;

    [self.eventTimerControl startWithEvent:event];
}

@end