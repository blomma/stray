//
//  EventsGroupedByDateViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsGroupedByDateViewController.h"

#import "Event.h"
#import "TagFilterButton.h"
#import "EventCell.h"
#import "State.h"
#import "Tag.h"
#import "NSDate+Utilities.h"
#import <Objective.h>
#import "TagsTableViewController.h"
#import <THObserversAndBinders.h>

@interface EventsGroupedByDateViewController ()

// Observer
@property (nonatomic) THObserver *selectedEventObserver;

@property (nonatomic) BOOL isFilterViewInvalid;
@property (nonatomic) UIScrollView *filterView;

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) id foregroundObserver;

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) BOOL isTableViewInvalid;

@property (nonatomic) CGFloat contentOffsetY;
@property (nonatomic) BOOL showFilterView;

@end

@implementation EventsGroupedByDateViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];

	self.tableView.contentInset = UIEdgeInsetsMake(30, 0, 0, 0);
	[self initFilterView];
	[self initBorder];

	self.isFilterViewInvalid = YES;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(longPressGestureRecognizer:)];
    [self.tableView addGestureRecognizer:longPress];

	__weak typeof(self) weakSelf = self;
	self.selectedEventObserver = [THObserver observerForObject:[State instance] keyPath:@"selectedEvent" oldAndNewBlock: ^(id oldValue, id newValue) {
        NSIndexPath *path = [weakSelf.fetchedResultsController indexPathForObject:oldValue];
        EventCell *cell = (EventCell *)[weakSelf.tableView cellForRowAtIndexPath:path];
        [cell marked:NO withAnimation:NO];
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	__weak typeof(self) weakSelf = self;

	self.foregroundObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                                                object:nil
                                                                                 queue:nil
                                                                            usingBlock: ^(NSNotification *note) {
                                                                                [weakSelf.tableView reloadData];
                                                                            }];

	if (self.isFilterViewInvalid)
		[self setupFilterView];

	if (self.isTableViewInvalid) {
		[self.tableView reloadData];
		self.isTableViewInvalid = NO;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self.foregroundObserver];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"segueToTagsFromEvents"]) {

		__weak typeof(self) weakSelf = self;

        TagsTableViewController *controller = (TagsTableViewController *)segue.destinationViewController;
		[controller setDidDismissHandler: ^{
		    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000);
		    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		        [weakSelf dismissViewControllerAnimated:YES completion:nil];
			});
		}];

		[controller setDidEditTagHandler: ^(Tag *tag) {
		    weakSelf.isFilterViewInvalid = YES;

		    NSUInteger index = [weakSelf.filterView.subviews indexOfObjectPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
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

		[controller setDidDeleteTagHandler: ^(Tag *tag) {
		    weakSelf.isFilterViewInvalid = YES;

		    NSUInteger index = [weakSelf.filterView.subviews indexOfObjectPassingTest: ^BOOL (id obj, NSUInteger idx, BOOL *stop) {
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

        [controller setDidSelectTagHandler:^(Tag *tag) {
            Event *event = (Event *)sender;
            event.inTag = [event.inTag isEqual:tag] ? nil : tag;
        }];

        [controller setIsTagSelectedHandler:^BOOL(Tag *tag) {
            Event *event = (Event *)sender;
            return [event.inTag isEqual:tag];
        }];
	}
}

#pragma mark -
#pragma mark Private properties

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

//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
//	return UITableViewCellEditingStyleDelete;
//}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)[[[self.fetchedResultsController sections] objectAtIndex:(NSUInteger)section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	EventCell *cell = (EventCell *)[tableView dequeueReusableCellWithIdentifier:@"EventCell"];
	[self configureCell:cell atIndexPath:indexPath];

	return cell;
}

- (void)configureCell:(EventCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];

	[cell.tagButton setTitle:event.inTag.name forState:UIControlStateNormal];

	// StartTime
	static NSUInteger unitFlagsEventStart = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
	NSDateComponents *components          = [[NSDate calendar] components:unitFlagsEventStart fromDate:event.startDate];

	cell.startTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
	cell.startDate.text  = [NSString stringWithFormat:@"%02d%@", components.day, [[self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1] uppercaseString]];


	// EventTime
	NSDate *stopDate                     = event.stopDate ? event.stopDate : [NSDate date];
	static NSUInteger unitFlagsEventTime = NSHourCalendarUnit | NSMinuteCalendarUnit;
	components                 = [[NSDate calendar] components:unitFlagsEventTime fromDate:event.startDate toDate:stopDate options:0];

	cell.hours.text   = [NSString stringWithFormat:@"%02d", components.hour];
	cell.minutes.text = [NSString stringWithFormat:@"%02d", components.minute];

	// StopTime
	if (event.stopDate) {
		static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
		components               = [[NSDate calendar] components:unitFlags fromDate:event.stopDate];

		cell.stopTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
		cell.stopDate.text  = [NSString stringWithFormat:@"%02d%@", components.day, [[self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1] uppercaseString]];
	} else {
		cell.stopTime.text  = @"";
		cell.stopDate.text   = @"";
	}

	BOOL marked = [[State instance].selectedEvent isEqual:event] ? YES : NO;

	[cell marked:marked withAnimation:NO];

	__weak typeof(self) weakSelf = self;

	__weak Event *weakEvent = event;

    [cell setDidSelectTagHandler:^{
	    [weakSelf performSegueWithIdentifier:@"segueToTagsFromEvents" sender:weakEvent];
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];

        [event delete];
        [State instance].selectedEvent = nil;
    }
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
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeUpdate:
			[self configureCell:(EventCell *)[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
			break;

		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView endUpdates];
}

#pragma mark -
#pragma mark Private methods

- (void)longPressGestureRecognizer:(UILongPressGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
        BOOL editing = !self.tableView.editing;
        [self.tableView setEditing:editing animated:YES];
	}
}

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

- (void)initBorder {
	UIView *bottomBorder = UIView.new;
	bottomBorder.layer.borderWidth = 0.5f;
	bottomBorder.layer.borderColor = [UIColor colorWithRed:0.729 green:0.729 blue:0.725 alpha:0.90].CGColor;

	[self.view addSubview:bottomBorder];

	[bottomBorder mas_makeConstraints: ^(MASConstraintMaker *make) {
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

	[self.filterView mas_makeConstraints: ^(MASConstraintMaker *make) {
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

			[button    addTarget:self
			              action:@selector(touchUpInsideTagFilterButton:forEvent:)
			    forControlEvents:UIControlEventTouchUpInside];

			if ([[State instance].eventsGroupedByDateFilter containsObject:tag.guid])
				button.selected = YES;

			[self.filterView addSubview:button];

			[button mas_makeConstraints: ^(MASConstraintMaker *make) {
			    make.top.equalTo(self.filterView.mas_top);
			    make.height.equalTo(self.filterView.mas_height);
			    make.width.equalTo(@100);
			}];

			if (previousView)
				[button mas_makeConstraints: ^(MASConstraintMaker *make) {
				    make.left.equalTo(previousView.mas_right);
				}];
			else
				[button mas_makeConstraints: ^(MASConstraintMaker *make) {
				    make.left.equalTo(self.filterView.mas_left);
				}];

			if (i == tags.count - 1)
				[button mas_makeConstraints: ^(MASConstraintMaker *make) {
				    make.right.equalTo(self.filterView.mas_right);
				}];

			previousView = button;
		}
	}

	self.isFilterViewInvalid = NO;
}

@end
