//
//  EventGroupViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 9/2/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsGroupedByStartDateViewController.h"

#import "Tag.h"
#import "Event.h"
#import "TagsTableViewController.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "UIScrollView+AIPulling.h"
#import "State.h"
#import "NSDate+Utilities.h"
#import "Stray-Swift.h"

@interface EventsGroupedByStartDateViewController ()<TransformableTableViewGestureEditingRowDelegate, EventCellDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSArray *shortStandaloneWeekdaySymbols;

@property (nonatomic) NSInteger editingCommitLength;

@property (nonatomic) Event *eventInEditState;
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation EventsGroupedByStartDateViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.editingCommitLength = 60;

    self.shortStandaloneMonthSymbols   = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.shortStandaloneWeekdaySymbols = [[NSDateFormatter new] shortStandaloneWeekdaySymbols];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    __weak __typeof__(self) _self = self;
    [self.tableView addPullingWithActionHandler:^(AIPullingState state, AIPullingState previousState, CGFloat height) {
        if (state == AIPullingStateAction && (previousState == AIPullingStatePullingAdd || previousState == AIPullingStatePullingClose)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _self.didDismissHandler();
            });
        }
    }];

    self.tableView.pullingView.addingHeight  = 0;
    self.tableView.pullingView.closingHeight = 60;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;

    // Check if we disapeared because of presenting a controller
    if (!self.presentedViewController) {
        [self.tableView disablePulling];
        [self.tableView disableGestureTableViewWithRecognizer:self.tableViewRecognizer];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvents"]) {
        TagsTableViewController *controller = (TagsTableViewController *)[segue destinationViewController];

        __weak __typeof__(self) _self = self;
        [controller setDidDismissHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self dismissViewControllerAnimated:YES completion:nil];
            });
        }];
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];

        [[segue destinationViewController] setEventGUID:event.guid];
    }
}

#pragma mark -
#pragma mark Private properties

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Event"];
        [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"startDate"
                                                                       ascending:YES]]];
        [fetchRequest setFetchBatchSize:20];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        
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

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.eventInEditState];
    
    if (state == TransformableTableViewCellEditingStateLeft && ![editStateIndexPath isEqual:indexPath]) {
        return;
    }
    
    EventCell *cell = (EventCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.frontView.layer removeAllAnimations];
    
    // If we have a cell in editstate and it is not this cell then cancel it
    if (self.eventInEditState && ![editStateIndexPath isEqual:indexPath]) {
        [self gestureRecognizer:gestureRecognizer
             cancelEditingState:state
              forRowAtIndexPath:editStateIndexPath];
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.eventInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && ![editStateIndexPath isEqual:indexPath]) {
        return;
    }
    
    EventCell *cell = (EventCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    
    CGFloat rightConstant = cell.frame.size.width - 200;
    CGFloat xOffset = [editStateIndexPath isEqual:indexPath] ? rightConstant : 0;
    
    cell.frontViewLeadingConstraint.constant = gestureRecognizer.translationInTableView.x + xOffset;
    cell.frontViewTrailingConstraint.constant = gestureRecognizer.translationInTableView.x + xOffset;
    
    [cell.frontView layoutIfNeeded];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.eventInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && ![editStateIndexPath isEqual:indexPath]) {
        return;
    }
    
    EventCell *cell = (EventCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    
    if (state == TransformableTableViewCellEditingStateRight && !self.eventInEditState) {
        CGFloat rightConstant = cell.frame.size.width - 200;
        CGFloat velocity = ABS(gestureRecognizer.velocity.x) / (rightConstant - cell.frontViewLeadingConstraint.constant);
        
        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.6f
              initialSpringVelocity:velocity
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             cell.frontViewLeadingConstraint.constant = rightConstant;
                             cell.frontViewTrailingConstraint.constant = rightConstant;
                             [cell.frontView layoutIfNeeded];
                         }
                         completion:nil];
        
        self.eventInEditState = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else {
        CGFloat velocity = ABS(gestureRecognizer.velocity.x) / cell.frontViewLeadingConstraint.constant;
        
        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.6f
              initialSpringVelocity:velocity
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             cell.frontViewLeadingConstraint.constant = 0;
                             cell.frontViewTrailingConstraint.constant = 0;
                             [cell.frontView layoutIfNeeded];
                         }
                         completion:nil];
        
        self.eventInEditState = nil;
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    EventCell *cell = (EventCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    
    CGFloat velocity = ABS(gestureRecognizer.velocity.x) / cell.frontViewLeadingConstraint.constant;
    
    [UIView animateWithDuration:1
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:velocity
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         cell.frontViewLeadingConstraint.constant = 0;
                         cell.frontViewTrailingConstraint.constant = 0;
                         [cell.frontView layoutIfNeeded];
                     }
                     completion:nil];

    self.eventInEditState = nil;
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.eventInEditState];
    
    // if this indexPath is in a edit state then return 0 else return normal
    return [editStateIndexPath isEqual:indexPath] ? 0 : self.editingCommitLength;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];

    EventCell *cell = (EventCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES animated:YES];

    [State instance].selectedEventGUID = event.guid;

    self.didDismissHandler();
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    EventCell *cell = (EventCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO animated:YES];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[[[self.fetchedResultsController sections] objectAtIndex:(NSUInteger)section] numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventCell *cell = (EventCell *)[tableView dequeueReusableCellWithIdentifier:@"EventCellIdentifier"];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(EventCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSAttributedString *attributeString = nil;
    if (event.inTag.name) {
        attributeString = [[NSAttributedString alloc] initWithString:event.inTag.name attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Futura-Medium" size:18]}];
    } else {
        attributeString = [[NSAttributedString alloc] initWithString:@"\uf02b" attributes:@{NSFontAttributeName:[UIFont fontWithName:@"FontAwesome" size:20]}];
    }

    [cell.tagButton setAttributedTitle:attributeString forState:UIControlStateNormal];
    
    // StartTime
    static NSUInteger unitFlagsEventStart = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents *components          = [[NSDate calendar] components:unitFlagsEventStart fromDate:event.startDate];
    
    cell.eventStartTime.text  = [NSString stringWithFormat:@"%02ld:%02ld", (long)components.hour, (long)components.minute];
    cell.eventStartDay.text   = [NSString stringWithFormat:@"%02ld", (long)components.day];
    cell.eventStartYear.text  = [NSString stringWithFormat:@"%04ld", (long)components.year];
    cell.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:(NSUInteger)components.month - 1];
    
    // EventTime
    NSDate *stopDate                     = event.stopDate ? event.stopDate : [NSDate date];
    static NSUInteger unitFlagsEventTime = NSCalendarUnitHour | NSCalendarUnitMinute;
    components                 = [[NSDate calendar] components:unitFlagsEventTime fromDate:event.startDate toDate:stopDate options:0];
    
    cell.eventTimeHours.text   = [NSString stringWithFormat:@"%02ld", (long)components.hour];
    cell.eventTimeMinutes.text = [NSString stringWithFormat:@"%02ld", (long)components.minute];
    
    // StopTime
    if (event.stopDate) {
        static NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
        components               = [[NSDate calendar] components:unitFlags fromDate:event.stopDate];
        
        cell.eventStopTime.text  = [NSString stringWithFormat:@"%02ld:%02ld", (long)components.hour, (long)components.minute];
        cell.eventStopDay.text   = [NSString stringWithFormat:@"%02ld", (long)components.day];
        cell.eventStopYear.text  = [NSString stringWithFormat:@"%04ld", (long)components.year];
        cell.eventStopMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:(NSUInteger)components.month - 1];
    } else {
        cell.eventStopTime.text  = @"";
        cell.eventStopDay.text   = @"";
        cell.eventStopYear.text  = @"";
        cell.eventStopMonth.text = @"";
    }
    
    if ([event.guid isEqual:[State instance].selectedEventGUID]) {
        [cell setSelected:YES animated:YES];
    }
    
    cell.delegate = self;
}

#pragma mark -
#pragma mark EventCellDelegate

- (void)didDeleteEventCell:(EventCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([event.guid isEqualToString:[State instance].selectedEventGUID]) {
        [State instance].selectedEventGUID = nil;
    }
    
    [event MR_deleteEntity];
    
    self.eventInEditState = nil;
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
}

- (void)didPressTag:(EventCell *)cell {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"segueToTagsFromEvents" sender:cell];
    });
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

@end