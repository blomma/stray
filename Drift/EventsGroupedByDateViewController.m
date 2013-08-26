//
//  EventsGroupedByDateViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsGroupedByDateViewController.h"

#import "Event.h"
#import "EventsGroupedByDate.h"
#import "EventGroup.h"
#import "TagFilterButton.h"
#import "EventSection.h"
#import "EventCell.h"
#import "State.h"
#import "Tag.h"
#import "NSDate+Utilities.h"
#import <Objective.h>

@interface EventsGroupedByDateViewController ()

@property (nonatomic) BOOL isFilterViewInvalid;
@property (nonatomic) UIScrollView *filterView;

@property (nonatomic) EventsGroupedByDate *eventGroups;
@property (nonatomic) BOOL isEventGroupsInvalid;
@property (nonatomic) BOOL isEventGroupsViewInvalid;

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *standaloneWeekdaySymbols;
@property (nonatomic) id managedContextObserver;
@property (nonatomic) id foregroundObserver;

@property (nonatomic) CGFloat contentOffsetY;
@property (nonatomic) BOOL showFilterView;

@end

@implementation EventsGroupedByDateViewController

- (void)viewDidLoad {
	[super viewDidLoad];

    [self.tableView registerClass:[EventSection class] forHeaderFooterViewReuseIdentifier:@"EventSection"];

	self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
	self.standaloneWeekdaySymbols    = [[NSDateFormatter new] standaloneWeekdaySymbols];

    self.tableView.contentInset = UIEdgeInsetsMake(30, 0, 0, 0);
	[self initFilterView];
    [self initBorder];

	NSArray *events = [Event allSortedBy:@{ @"startDate" : @YES }];
	self.eventGroups = [[EventsGroupedByDate alloc] initWithEvents:events
	                                                   withFilters:[State instance].eventsGroupedByDateFilter];
	self.isEventGroupsInvalid = YES;
	self.isEventGroupsViewInvalid = YES;
	self.isFilterViewInvalid = YES;

	__weak typeof(self) weakSelf = self;

	void (^notificationBlock)(NSNotification *) = ^(NSNotification *note) {
		NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
		NSSet *deletedObjects  = [[note userInfo] objectForKey:NSDeletedObjectsKey];
		NSSet *updatedObjects  = [[note userInfo] objectForKey:NSUpdatedObjectsKey];

		// ==========
		// = Events =
		// ==========
		NSSet *updatedEvents = [updatedObjects objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
		    return [obj isKindOfClass:[Event class]];
		}];

		NSSet *insertedEvents = [insertedObjects objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
		    return [obj isKindOfClass:[Event class]];
		}];

		NSSet *deletedEvents = [deletedObjects objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
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
		NSSet *updatedTags = [updatedObjects objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
		    return [obj isKindOfClass:[Tag class]];
		}];

		NSSet *insertedTags = [insertedObjects objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
		    return [obj isKindOfClass:[Tag class]];
		}];

		NSSet *deletedTags = [deletedObjects objectsPassingTest: ^BOOL (id obj, BOOL *stop) {
		    return [obj isKindOfClass:[Tag class]];
		}];

		if (updatedTags.count > 0 || insertedTags.count > 0)
			weakSelf.isFilterViewInvalid = YES;

		for (Tag *tag in deletedTags) {
			NSUInteger index = [weakSelf.filterView.subviews indexOfObjectPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
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
	};

	self.managedContextObserver = [[NSNotificationCenter defaultCenter]
	                               addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                   object:[NSManagedObjectContext defaultContext]
                                   queue:nil
                                   usingBlock:notificationBlock];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	__weak typeof(self) weakSelf = self;

	self.foregroundObserver = [[NSNotificationCenter defaultCenter]
	                           addObserverForName:UIApplicationWillEnterForegroundNotification
                               object:nil
                               queue:nil
                               usingBlock: ^(NSNotification *note) {
                                   [weakSelf.tableView reloadData];
                               }];

	if (self.isFilterViewInvalid)
		[self setupFilterView];

	if (self.isEventGroupsViewInvalid) {
		[self.tableView reloadData];

		self.isEventGroupsViewInvalid = NO;
	}

    [self.tableView setEditing:YES animated:YES];
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
#pragma mark UIScrollViewDelegate

//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//	self.contentOffsetY = scrollView.contentOffset.y + scrollView.contentInset.top;
//}
//
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//	// We are only interested in doing this at the top of the stack
//	CGFloat offSet = scrollView.contentOffset.y + scrollView.contentInset.top;
//	CGFloat top = [UIApplication sharedApplication].statusBarFrame.size.height + 30.0f;
//
//	if (offSet <= top) {
//		if ((self.contentOffsetY > offSet || offSet < 0)) {
//			CGFloat y = MIN(30 - (scrollView.contentOffset.y + scrollView.contentInset.top), 30);
//            [self.filterView mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.top.equalTo(@(y));
//            }];
//		} else if (self.contentOffsetY < offSet) {
//			CGFloat y = MAX(30 - (scrollView.contentOffset.y + scrollView.contentInset.top), -30);
//            [self.filterView mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.top.equalTo(@(y));
//            }];
//		}
//	} else if (offSet > top) {
//		if (self.showFilterView) {
//			CGFloat y = MIN(30 - (scrollView.contentOffset.y + scrollView.contentInset.top), 30);
//            [self.filterView mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.top.equalTo(@(y));
//            }];
//		} else {
//			CGFloat y = MAX(30 - (scrollView.contentOffset.y + scrollView.contentInset.top), -30);
//            [self.filterView mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.top.equalTo(@(y));
//            }];
//		}
//	}
//
//	self.contentOffsetY = scrollView.contentOffset.y;
//}
//
////- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
////	CGRect frame = CGRectMake(self.filterView.frame.origin.x,
////	                          30,
////	                          self.filterView.frame.size.width,
////	                          self.filterView.frame.size.height);
////
////	[UIView animateWithDuration:0.2 animations: ^{
////	    self.filterView.frame = frame;
////	}];
////}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//	// If this was a flick of the finger and it was in a downward direction (scrolling up) then show the tagview
//	// else we hide it
//	CGFloat offSet = scrollView.contentOffset.y + scrollView.contentInset.top;
//	if (decelerate && self.contentOffsetY > offSet)
//		self.showFilterView = YES;
//	else
//		self.showFilterView = NO;
//}

#pragma mark -
#pragma mark UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
        return UITableViewCellEditingStyleDelete;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    EventSection *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"EventSection"];

	EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)section];

	NSDateComponents *components = eventGroup.filteredEventsDateComponents;

	header.hour.text   = [NSString stringWithFormat:@"%02d", components.hour];
//	cell.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];
//
//	static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
//	components = [[NSDate calendar] components:unitFlags fromDate:eventGroup.groupDate];
//
//	cell.day.text     = [NSString stringWithFormat:@"%02d", components.day];
//	cell.year.text    = [NSString stringWithFormat:@"%04d", components.year];
//	cell.month.text   = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
//	cell.weekDay.text = [[self.standaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString];

	return header;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (NSInteger)self.eventGroups.filteredEventGroupCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)section];
	return (NSInteger)eventGroup.filteredEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	EventCell *cell = (EventCell *)[tableView dequeueReusableCellWithIdentifier:@"EventCell"];
	[self configureCell:cell atIndexPath:indexPath];

	return cell;
}

- (void)configureCell:(EventCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	EventGroup *eventGroup = [self.eventGroups filteredEventGroupAtIndex:(NSUInteger)indexPath.section];
	Event *event = [eventGroup.filteredEvents objectAtIndex:(NSUInteger)indexPath.row];

	[cell.tagName setTitle:[event.inTag.name copy] forState:UIControlStateNormal];

	// StartTime
	static NSUInteger unitFlagsEventStart = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
	NSDateComponents *components          = [[NSDate calendar] components:unitFlagsEventStart fromDate:event.startDate];

	cell.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
	cell.eventStartDay.text   = [NSString stringWithFormat:@"%02d", components.day];
	cell.eventStartYear.text  = [NSString stringWithFormat:@"%04d", components.year];
	cell.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];

	// EventTime
	NSDate *stopDate                     = event.stopDate ? event.stopDate : [NSDate date];
	static NSUInteger unitFlagsEventTime = NSHourCalendarUnit | NSMinuteCalendarUnit;
	components                 = [[NSDate calendar] components:unitFlagsEventTime fromDate:event.startDate toDate:stopDate options:0];

	cell.eventTimeHours.text   = [NSString stringWithFormat:@"%02d", components.hour];
	cell.eventTimeMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];

	// StopTime
	if (event.stopDate) {
		static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
		components               = [[NSDate calendar] components:unitFlags fromDate:event.stopDate];

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

	BOOL marked = [[State instance].selectedEvent isEqual:event] ? YES : NO;
	[cell marked:marked withAnimation:YES];

	__weak typeof(self) weakSelf = self;

	__weak Event *weakEvent = event;
	[cell setTagPressHandler: ^{
	    [weakSelf performSegueWithIdentifier:@"segueToTagsFromEvents" sender:weakEvent];
	}];
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

- (void)initBorder {
    UIView *bottomBorder = UIView.new;
    bottomBorder.layer.borderWidth = 0.5f;
    bottomBorder.layer.borderColor = [UIColor colorWithRed:0.729 green:0.729 blue:0.725 alpha:0.90].CGColor;

    [self.view addSubview:bottomBorder];

    [bottomBorder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.filterView.mas_bottom);
        make.left.equalTo(self.filterView.mas_left);
        make.right.equalTo(self.filterView.mas_right);
        make.height.equalTo(@0.5);
    }];
}

- (void)initFilterView {
    self.filterView = UIScrollView.new;
	self.filterView.showsHorizontalScrollIndicator = NO;
	self.filterView.backgroundColor                = [UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:1];

    [self.view addSubview:self.filterView];

    [self.filterView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@20);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.height.equalTo(@30);
    }];
}

- (void)setupFilterView {
	for (id button in self.filterView.subviews) {
		[button removeFromSuperview];
	}

	NSArray *tags = [Tag allSortedBy:@{ @"sortIndex" : @YES }];

    UIView *previousView;
	for (NSUInteger i = 0; i < tags.count; i++) {
		Tag *tag = [tags objectAtIndex:i];

		// Only show tags that have a name set
		if (tag.name) {
			TagFilterButton *button = TagFilterButton.new;
			[button setTitle:[tag.name uppercaseString] forState:UIControlStateNormal];
			button.tagGuid = tag.guid;

           [button addTarget:self
                      action:@selector(touchUpInsideTagFilterButton:forEvent:)
            forControlEvents:UIControlEventTouchUpInside];

			if ([[State instance].eventsGroupedByDateFilter containsObject:tag.guid])
				button.selected = YES;

			[self.filterView addSubview:button];

            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.filterView.mas_top);
                make.height.equalTo(self.filterView.mas_height);
                make.width.equalTo(@100);
            }];

            if (previousView) {
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(previousView.mas_right);
                }];
            } else {
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(self.filterView.mas_left);
                }];
            }

            if (i == tags.count - 1) {
                [button mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(self.filterView.mas_right);
                }];
            }

            previousView = button;
		}
	}

	self.isFilterViewInvalid = NO;
}

@end
