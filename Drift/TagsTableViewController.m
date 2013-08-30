//
//  TagsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "State.h"
#import "TagsTableViewController.h"
#import "TagTableViewCell.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "UIScrollView+AIPulling.h"
#import <Objective.h>

@interface TagsTableViewController () <TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGestureMovingRowDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) Tag *tagInEditState;

@property (nonatomic) NSIndexPath *transformingMovingIndexPath;

@property (nonatomic) NSInteger editingStateRightOffset;
@property (nonatomic) NSInteger editingCommitLength;

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation TagsTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.editingStateRightOffset = 260;
	self.editingCommitLength     = 60;

	self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"grabbedTableViewCellIdentifier"];

	__weak typeof(self) weakSelf = self;

	[self.tableView addPullingWithActionHandler: ^(AIPullingState state, AIPullingState previousState, CGFloat height) {
	    if (state == AIPullingStateAction && previousState == AIPullingStatePullingAdd) {
	        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000);
	        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
	            [Tag create];
			});
		} else if (state == AIPullingStateAction && previousState == AIPullingStatePullingClose) {
	        if (weakSelf.didDismissHandler)
				weakSelf.didDismissHandler();
		}
	}];

	self.tableView.pullingView.addingHeight  = 60;
	self.tableView.pullingView.closingHeight = 90;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self.tableView disablePulling];
	[self.tableView disableGestureTableViewWithRecognizer:self.tableViewRecognizer];
}

#pragma mark -
#pragma mark Private properties

- (NSFetchedResultsController *)fetchedResultsController {
	if (_fetchedResultsController == nil) {
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription
		                               entityForName:@"Tag"
                                       inManagedObjectContext:[NSManagedObjectContext defaultContext]];
		[fetchRequest setEntity:entity];

		NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"sortIndex" ascending:YES];
		[fetchRequest setSortDescriptors:@[sort]];

		[fetchRequest setFetchBatchSize:20];

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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.tagInEditState) {
		NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];

		[self gestureRecognizer:self.tableViewRecognizer
		     cancelEditingState:Right
		      forRowAtIndexPath:indexPath];
	}
}

#pragma mark -
#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)[[[self.fetchedResultsController sections] objectAtIndex:(NSUInteger)section] numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (NSInteger)[[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.transformingMovingIndexPath && [self.transformingMovingIndexPath isEqual:indexPath]) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"grabbedTableViewCellIdentifier"];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;

		return cell;
	} else {
		TagTableViewCell *cell = (TagTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TagsTableViewCellIdentifier"];
		[self configureCell:cell atIndexPath:indexPath];

		return cell;
	}
}

- (void)configureCell:(TagTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.tagTitle = [tag.name copy];
	BOOL selected = [self.event.inTag isEqual:tag] ? YES : NO;
	[cell marked:selected withAnimation:NO];

	__weak typeof(self) weakSelf = self;

	__weak Tag *weakTag = tag;
	__weak TagTableViewCell *weakCell = cell;

	[cell setDidDeleteHandler: ^{
	    CGPoint toValue   = CGPointMake(CGRectGetMidX(weakCell.frontView.layer.bounds), weakCell.frontView.layer.position.y);

        [weakSelf animateBounceOnView:weakCell.frontView toCenter:toValue];

	    weakSelf.tagInEditState = nil;

	    [weakTag delete];

	    if (self.didDeleteTagHandler)
			self.didDeleteTagHandler(weakTag);
	}];

	[cell setDidEditHandler: ^(NSString *name) {
	    if (name && ![name isEqualToString:@""]) {
	        weakTag.name = [name copy];
	        weakCell.tagTitle = [name copy];

	        if (weakSelf.didEditTagHandler)
				weakSelf.didEditTagHandler(weakTag);
		}

	    CGPoint toValue   = CGPointMake(CGRectGetMidX(weakCell.frontView.layer.bounds), weakCell.frontView.layer.position.y);

        [weakSelf animateBounceOnView:weakCell.frontView toCenter:toValue];

	    self.tagInEditState = nil;
	}];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

	[cell marked:NO withAnimation:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];

	// If this is a tag with no name then we cant select it
	if (!tag.name)
		return;

	// Now we check if we have any cells in editstate,
	// if so we animate them back to normal state
	if (self.tagInEditState) {
		NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];

		TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:editStateIndexPath];
		CGPoint toValue        = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), cell.frontView.layer.position.y);

        [self animateBounceOnView:cell.frontView toCenter:toValue];
	}

	TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

	[cell marked:!cell.marked withAnimation:YES];

	self.event.inTag = [self.event.inTag isEqual:tag] ? nil : tag;

	if (self.didDismissHandler)
		self.didDismissHandler();
}

#pragma mark -
#pragma mark TransformableTableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];

	if (state == Left && ![editStateIndexPath isEqual:indexPath])
		return;

	TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
	[cell.frontView.layer removeAllAnimations];

	// If we have a cell in editstate and it is not this cell then cancel it
	if (self.tagInEditState && ![editStateIndexPath isEqual:indexPath])
		[self gestureRecognizer:gestureRecognizer cancelEditingState:state forRowAtIndexPath:editStateIndexPath];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];
	if (state == Left && ![editStateIndexPath isEqual:indexPath])
		return;

	TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

	NSInteger xOffset = 0;
	if ([editStateIndexPath isEqual:indexPath])
		xOffset = self.editingStateRightOffset;

	CGPoint point = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + gestureRecognizer.translationInTableView.x + xOffset, cell.frontView.layer.position.y);
	cell.frontView.layer.position = point;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];
	if (state == Left && ![editStateIndexPath isEqual:indexPath])
		return;

	TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

	if (state == Right && !self.tagInEditState) {
		CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + self.editingStateRightOffset, cell.frontView.layer.position.y);

        [self animateBounceOnView:cell.frontView toCenter:toValue];

		self.tagInEditState = [self.fetchedResultsController objectAtIndexPath:indexPath];
	} else {
		CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), cell.frontView.layer.position.y);

		// Dimiss if we are showing it
		[cell.tagNameTextField resignFirstResponder];

        [self animateBounceOnView:cell.frontView toCenter:toValue];

		self.tagInEditState = nil;
	}
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath {
	TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
	[cell.tagNameTextField resignFirstResponder];

	CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), cell.frontView.layer.position.y);

	self.tagInEditState = nil;

    [self animateBounceOnView:cell.frontView toCenter:toValue];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];
	// if this indexPath is in a edit state then return 0 else return normal
	if ([editStateIndexPath isEqual:indexPath])
		return 0;
	else
		return self.editingCommitLength;
}

#pragma mark -
#pragma mark TransformableTableViewGestureMovingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
	self.transformingMovingIndexPath = indexPath;

	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)atIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	self.transformingMovingIndexPath = toIndexPath;

	Tag *atTag = [self.fetchedResultsController objectAtIndexPath:atIndexPath];
	Tag *toTag = [self.fetchedResultsController objectAtIndexPath:toIndexPath];

	atTag.sortIndex = [NSNumber numberWithInteger:toIndexPath.row];
	toTag.sortIndex = [NSNumber numberWithInteger:atIndexPath.row];

	[self.tableView beginUpdates];

	[self.tableView deleteRowsAtIndexPaths:@[atIndexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView insertRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationFade];

	[self.tableView endUpdates];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
	self.transformingMovingIndexPath = nil;

	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	if (self.transformingMovingIndexPath)
		return;

	UITableView *tableView = self.tableView;

	switch (type) {
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeUpdate:
			[self configureCell:(TagTableViewCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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
