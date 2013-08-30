//
//  EventGroupViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventCell.h"
#import "EventsGroupedByStartDateViewController.h"
#import "NSDate+Utilities.h"
#import "State.h"
#import "TagFilterButton.h"
#import "TagsTableViewController.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "UIScrollView+AIPulling.h"
#import <Objective.h>

@interface EventsGroupedByStartDateViewController () <TransformableTableViewGestureEditingRowDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *shortStandaloneWeekdaySymbols;

@property (nonatomic) NSMutableArray *filterViewButtons;
@property (nonatomic) BOOL isFilterViewInvalid;

@property (nonatomic, readonly) NSInteger editingCommitLength;
@property (nonatomic) id foregroundObserver;

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL isTableViewInvalid;

@end

@implementation EventsGroupedByStartDateViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.shortStandaloneMonthSymbols   = [[NSDateFormatter new] shortStandaloneMonthSymbols];
	self.shortStandaloneWeekdaySymbols = [[NSDateFormatter new] shortStandaloneWeekdaySymbols];

	[self initFilterView];

	self.isFilterViewInvalid = YES;

	self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

	__weak typeof(self) weakSelf = self;

	[self.tableView addPullingWithActionHandler: ^(AIPullingState state, AIPullingState previousState, CGFloat height) {
	    if (state == AIPullingStateAction && (previousState == AIPullingStatePullingAdd || previousState == AIPullingStatePullingClose))
			if (weakSelf.didDismissHandler)
				weakSelf.didDismissHandler();
	}];

	self.tableView.pullingView.addingHeight  = 0;
	self.tableView.pullingView.closingHeight = 60;

	self.tableView.contentInset = UIEdgeInsetsMake(50, 0, 30, 0);
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(50, 0, 30, 0);
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	if (self.isFilterViewInvalid)
		[self setupFilterView];

	if (self.isTableViewInvalid) {
		[self.tableView reloadData];
		self.isTableViewInvalid = NO;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// Check if we disapeared because of presenting a controller
	if (!self.presentedViewController) {
		[self.tableView disablePulling];
		[self.tableView disableGestureTableViewWithRecognizer:self.tableViewRecognizer];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"segueToTagsFromEvents"]) {
		__weak typeof(self) weakSelf = self;

		[[segue destinationViewController] setDidDismissHandler: ^{
		    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000);
		    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		        [weakSelf dismissViewControllerAnimated:YES completion:nil];
			});
		}];

		[[segue destinationViewController] setDidEditTagHandler: ^(Tag *tag) {
		    weakSelf.isFilterViewInvalid = YES;

		    NSUInteger index = [weakSelf.filterViewButtons indexOfObjectPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
		        if ([tag.guid isEqualToString:[obj tagGuid]]) {
		            *stop = YES;
		            return YES;
				}

		        return NO;
			}];

		    if (index != NSNotFound) {
		        weakSelf.isTableViewInvalid = YES;
		        weakSelf.fetchedResultsController = nil;
			}
		}];

		[[segue destinationViewController] setDidDeleteTagHandler: ^(Tag *tag) {
		    weakSelf.isFilterViewInvalid = YES;

		    NSUInteger index = [weakSelf.filterViewButtons indexOfObjectPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
		        if ([tag.guid isEqualToString:[obj tagGuid]]) {
		            *stop = YES;
		            return YES;
				}

		        return NO;
			}];

		    if (index != NSNotFound) {
		        [[State instance].eventsGroupedByStartDateFilter removeObject:tag.guid];

		        weakSelf.isTableViewInvalid = YES;
		        weakSelf.fetchedResultsController = nil;
			}
		}];

		[[segue destinationViewController] setEvent:sender];
	}
}

#pragma mark -
#pragma mark Private properties

- (NSInteger)editingCommitLength {
	return 200;
}

- (NSFetchedResultsController *)fetchedResultsController {
	if (_fetchedResultsController == nil) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription
		                               entityForName:@"Event"
                                       inManagedObjectContext:[NSManagedObjectContext defaultContext]];
		[fetchRequest setEntity:entity];

		NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"startDate"
		                                                     ascending:NO];

		[fetchRequest setSortDescriptors:@[sort]];

		NSPredicate *predicate = nil;
		if ([State instance].eventsGroupedByStartDateFilter.count > 0) {
			predicate = [NSPredicate predicateWithFormat:@"inTag.guid IN %@", [State instance].eventsGroupedByStartDateFilter];
			[fetchRequest setPredicate:predicate];
		}


		[fetchRequest setFetchBatchSize:10];

		NSFetchedResultsController *theFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                            managedObjectContext:[NSManagedObjectContext defaultContext]
                                              sectionNameKeyPath:nil
                                                       cacheName:nil];

		_fetchedResultsController = theFetchedResultsController;
		_fetchedResultsController.delegate = self;

		NSError *error;
		if (![_fetchedResultsController performFetch:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);
		}
	}

	return _fetchedResultsController;
}

#pragma mark -
#pragma mark TransformableTableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (state == Left)
		return;

	EventCell *cell = (EventCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
	[cell.frontView.layer removeAllAnimations];

	cell.willDelete.hidden = YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (state == Left)
		return;

	EventCell *cell = (EventCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
	CGFloat alpha                               = (gestureRecognizer.translationInTableView.x / self.editingCommitLength);
	cell.backView.backgroundColor = [UIColor colorWithRed:0.843f
	                                                green:0.306f
	                                                 blue:0.314f
	                                                alpha:alpha];

	CGPoint frontViewPoint = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + gestureRecognizer.translationInTableView.x, cell.frontView.layer.position.y);
	cell.frontView.layer.position = frontViewPoint;

	cell.willDelete.hidden = alpha >= 1 ? NO : YES;

	if (alpha >= 1) {
		CGPoint willDeletePoint = CGPointMake(CGRectGetMinX(cell.frontView.layer.bounds) + gestureRecognizer.translationInTableView.x - 20, cell.frontView.layer.position.y);
		cell.willDelete.layer.position = willDeletePoint;
	}
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (state == Left)
		return;

	Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];

	// Are we about to remove the selected event
	if ([[State instance].selectedEvent isEqual:event])
		[State instance].selectedEvent = nil;

	[event delete];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	EventCell *cell = (EventCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
	CGPoint toValue                             = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), cell.frontView.layer.position.y);

    [self animateBounceOnView:cell.frontView toCenter:toValue];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.editingCommitLength;
}

#pragma mark -
#pragma mark UITableViewDelegate

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//	id sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:(NSUInteger)section];
//
//	CGRect frame = CGRectMake(0, 0.0, tableView.bounds.size.width, 36.0);
//
//	UILabel *headerLabel = [[UILabel alloc] initWithFrame:frame];
//	headerLabel.backgroundColor = [UIColor colorWithRed:0.745 green:0.106 blue:0.169 alpha:0.8];
//	headerLabel.opaque          = YES;
//	headerLabel.textColor       = [UIColor whiteColor];
//	headerLabel.font            = [UIFont fontWithName:@"Futura-CondensedMedium" size:16];
//	headerLabel.textAlignment   = NSTextAlignmentCenter;
//
//	headerLabel.text = [sectionInfo name];
//	//    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//	//    [dateFormat setDateFormat:@"yyyy-MM-dd"];
//	//    NSDate *date = [dateFormat dateFromString:[sectionInfo name]];
//	//
//	//	static NSUInteger unitFlagsEventStart = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit;
//	//	NSDateComponents *components          = [[NSDate calendar] components:unitFlagsEventStart fromDate:date];
//	//
//	//	headerLabel.text = [NSString stringWithFormat:@"%@  ·  %02d %@ %04d",
//	//	                    [[self.shortStandaloneWeekdaySymbols objectAtIndex:components.weekday - 1] uppercaseString],
//	//	                    components.day,
//	//	                    [[self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1] uppercaseString],
//	//	                    components.year];
//
//	return headerLabel;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	EventCell *cell = (EventCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	[cell marked:YES withAnimation:YES];

	[State instance].selectedEvent = [self.fetchedResultsController objectAtIndexPath:indexPath];

	if (self.didDismissHandler)
		self.didDismissHandler();
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	EventCell *cell = (EventCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	[cell marked:NO withAnimation:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//	return (NSInteger)[[self.fetchedResultsController sections] count];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)[[[self.fetchedResultsController sections] objectAtIndex:(NSUInteger)section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"EventsGroupedByStartDateTableViewCell";

	EventCell *cell = (EventCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	[self configureCell:cell atIndexPath:indexPath];

	return cell;
}

- (void)configureCell:(EventCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];

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
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	UITableView *tableView = self.tableView;

	switch (type) {
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeUpdate:
			[self configureCell:(EventCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;

		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray
			                                   arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:[NSArray
			                                   arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView endUpdates];
}

#pragma mark -
#pragma mark Private methods

- (void)touchUpInsideTagFilterButton:(TagFilterButton *)sender forEvent:(UIEvent *)event {
	if ([[State instance].eventsGroupedByStartDateFilter containsObject:sender.tagGuid]) {
		[[State instance].eventsGroupedByStartDateFilter removeObject:sender.tagGuid];

		sender.selected = NO;
	} else {
		[[State instance].eventsGroupedByStartDateFilter addObject:sender.tagGuid];

		sender.selected = YES;
	}

	self.fetchedResultsController = nil;
	[self.tableView reloadData];
}

- (void)initFilterView {
	self.filterViewButtons = [NSMutableArray array];

	self.filterView.showsHorizontalScrollIndicator = NO;
	self.filterView.backgroundColor                = [UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:0.9];

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

	NSArray *tags = [Tag allSortedBy:@{ @"sortIndex" : @YES }];

	// add elements
	for (NSUInteger i = 0; i < tags.count; i++) {
		Tag *tag = [tags objectAtIndex:i];

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

			if ([[State instance].eventsGroupedByStartDateFilter containsObject:tag.guid])
				button.selected = YES;

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

- (void)animateBounceOnView:(UIView *)view toCenter:(CGPoint)to {
    [UIView animateWithDuration:1.5
                          delay:0
         usingSpringWithDamping:0.3f
          initialSpringVelocity:2.5f
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         view.center = to;
                     } completion:nil];
}

@end
