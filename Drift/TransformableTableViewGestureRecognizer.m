// 
//  TransformableTableViewGestureRecognizer.m
//  stray
//  
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Artsoftheinsane. All rights reserved.
// 

#import "TransformableTableViewGestureRecognizer.h"

typedef NS_ENUM (uint16_t, TableViewGestureRecognizerState) {
	TableViewGestureRecognizerStateNone,
	TableViewGestureRecognizerStatePanning,
	TableViewGestureRecognizerStateMoving
};

static CGFloat kCommitEditingRowDefaultLength = 80;
static CGFloat kAddingAnimationDuration       = 0.25;

@interface TransformableTableViewGestureRecognizer () <UIGestureRecognizerDelegate>

// public properties
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic) CGPoint translationInTableView;

// private properties
@property (nonatomic, weak) id <TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGestureMovingRowDelegate> delegate;

// Editing
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic) TransformableTableViewCellEditingState editingCellState;

// Moving
@property (nonatomic) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic) NSTimer *movingTimer;

@property (nonatomic) TableViewGestureRecognizerState state;

@property (nonatomic) CGFloat scrollingRate;
@property (nonatomic) NSIndexPath *transformIndexPath;

@end

static NSInteger kCellSnapShotTag = 100000;

@implementation TransformableTableViewGestureRecognizer

- (void)scrollTable {
	// Scroll tableview while touch point is on top or bottom part
	CGPoint location = [self.longPressRecognizer locationInView:self.tableView];

	CGPoint currentOffset = self.tableView.contentOffset;
	CGPoint newOffset     = CGPointMake(currentOffset.x, currentOffset.y + self.scrollingRate);
	if (newOffset.y < 0) {
		newOffset.y = 0;
	} else if (self.tableView.contentSize.height < self.tableView.frame.size.height) {
		newOffset = currentOffset;
	} else if (newOffset.y > self.tableView.contentSize.height - self.tableView.frame.size.height) {
		newOffset.y = self.tableView.contentSize.height - self.tableView.frame.size.height;
	} else {
	}

	if (fabs(currentOffset.y) != fabs(newOffset.y)) {
		[self.tableView setContentOffset:newOffset];

		UIImageView *cellSnapshotView = (id)[self.tableView viewWithTag : kCellSnapShotTag];
		cellSnapshotView.center = CGPointMake(self.tableView.center.x, location.y);
	}
}

#pragma mark Action

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan && [recognizer numberOfTouches] > 0) {
		CGPoint translation = [recognizer translationInView:self.tableView];
		self.translationInTableView = translation;

		NSIndexPath *indexPath = self.transformIndexPath;
		if (!indexPath) {
			CGPoint location = [recognizer locationOfTouch:0 inView:self.tableView];

			indexPath               = [self.tableView indexPathForRowAtPoint:location];
			self.transformIndexPath = indexPath;
		}

		self.editingCellState = translation.x >= 0 ? TransformableTableViewCellEditingStateRight : TransformableTableViewCellEditingStateLeft;
		self.state            = TableViewGestureRecognizerStatePanning;

		if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didEnterEditingState:forRowAtIndexPath:)])
			[self.delegate gestureRecognizer:self didEnterEditingState:self.editingCellState forRowAtIndexPath:indexPath];
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		NSIndexPath *indexPath = self.transformIndexPath;
		CGPoint translation    = [recognizer translationInView:self.tableView];
		self.translationInTableView = translation;

		self.editingCellState = translation.x > 0 ? TransformableTableViewCellEditingStateRight : TransformableTableViewCellEditingStateLeft;

		if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didChangeEditingState:forRowAtIndexPath:)])
			[self.delegate gestureRecognizer:self didChangeEditingState:self.editingCellState forRowAtIndexPath:indexPath];
	} else if (recognizer.state == UIGestureRecognizerStateEnded) {
		NSIndexPath *indexPath = self.transformIndexPath;

		self.transformIndexPath = nil;

		CGPoint translation = [recognizer translationInView:self.tableView];

		CGFloat commitEditingLength = kCommitEditingRowDefaultLength;
		if ([self.delegate respondsToSelector:@selector(gestureRecognizer:lengthForCommitEditingRowAtIndexPath:)])
			commitEditingLength = [self.delegate gestureRecognizer:self lengthForCommitEditingRowAtIndexPath:indexPath];

		if (fabsf(translation.x) >= commitEditingLength) {
			if ([self.delegate respondsToSelector:@selector(gestureRecognizer:commitEditingState:forRowAtIndexPath:)])
				[self.delegate gestureRecognizer:self commitEditingState:self.editingCellState forRowAtIndexPath:indexPath];
		} else {
			if ([self.delegate respondsToSelector:@selector(gestureRecognizer:cancelEditingState:forRowAtIndexPath:)])
				[self.delegate gestureRecognizer:self cancelEditingState:self.editingCellState forRowAtIndexPath:indexPath];
		}

		self.editingCellState = TransformableTableViewCellEditingStateNone;
		self.state            = TableViewGestureRecognizerStateNone;
	}
}

- (void)longPressGestureRecognizer:(UILongPressGestureRecognizer *)recognizer {
	CGPoint location = [recognizer locationInView:self.tableView];

	if (recognizer.state == UIGestureRecognizerStateBegan) {
		NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
		self.state = TableViewGestureRecognizerStateMoving;

		// We create an imageView for caching the cell snapshot here
		UIImageView *snapShotView = (UIImageView *)[self.tableView viewWithTag:kCellSnapShotTag];
		if (!snapShotView) {
			UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

			UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
			[cell.layer renderInContext:UIGraphicsGetCurrentContext()];
			UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

			snapShotView     = [[UIImageView alloc] initWithImage:cellImage];
			snapShotView.tag = kCellSnapShotTag;

			[self.tableView addSubview:snapShotView];

			CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
			snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
		}

		// Make a zoom in effect for the cell
		[UIView animateWithDuration:kAddingAnimationDuration animations: ^{
		    snapShotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
		    snapShotView.center = CGPointMake(self.tableView.center.x, location.y);
		    snapShotView.alpha = 0.65;
		}];

		[self.delegate gestureRecognizer:self needsCreatePlaceholderForRowAtIndexPath:indexPath];
		self.transformIndexPath = indexPath;

		// Start timer to prep area for auto scrolling
		self.movingTimer = [NSTimer timerWithTimeInterval:1 / 8 target:self selector:@selector(scrollTable) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:self.movingTimer forMode:NSDefaultRunLoopMode];
	} else if (recognizer.state == UIGestureRecognizerStateEnded) {
		// While long press ends, we remove the snapshot imageView

		UIImageView *snapShotView = (UIImageView *)[self.tableView viewWithTag:kCellSnapShotTag];
		__weak typeof(self) weakSelf = self;

		// Stop timer
		[self.movingTimer invalidate];
		self.movingTimer   = nil;
		self.scrollingRate = 0;

		[UIView animateWithDuration:kAddingAnimationDuration
		                 animations: ^{
                             CGRect rect = [weakSelf.tableView rectForRowAtIndexPath:weakSelf.transformIndexPath];
                             snapShotView.transform = CGAffineTransformIdentity;                                      // restore the transformed value
                             snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
                             snapShotView.alpha = 1;
                         } completion: ^(BOOL finished) {
                             [snapShotView removeFromSuperview];

                             [weakSelf.delegate gestureRecognizer:weakSelf needsReplacePlaceholderForRowAtIndexPath:weakSelf.transformIndexPath];

                             // Update state and clear instance variables
                             weakSelf.transformIndexPath = nil;
                             weakSelf.state = TableViewGestureRecognizerStateNone;
                         }];
	} else if (recognizer.state == UIGestureRecognizerStateChanged) {
		NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

		// While our finger moves, we also moves the snapshot imageView
		UIImageView *snapShotView = (UIImageView *)[self.tableView viewWithTag:kCellSnapShotTag];
		snapShotView.center = CGPointMake(self.tableView.center.x, location.y);

		CGRect rect = self.tableView.bounds;
		location.y -= self.tableView.contentOffset.y;       // We needed to compensate actual contentOffset.y to get the relative y position of touch.

		// Refresh the indexPath since it may change while we use a new offset
		if (indexPath && ![indexPath isEqual:self.transformIndexPath]) {
			[self.delegate gestureRecognizer:self needsMoveRowAtIndexPath:self.transformIndexPath toIndexPath:indexPath];
			self.transformIndexPath = indexPath;
		}

		CGFloat bottomDropZoneHeight = self.tableView.bounds.size.height / 6;
		CGFloat topDropZoneHeight    = bottomDropZoneHeight;
		CGFloat bottomDiff           = location.y - (rect.size.height - bottomDropZoneHeight);
		if (bottomDiff > 0)
			self.scrollingRate = bottomDiff / (bottomDropZoneHeight / 1);
		else if (location.y <= topDropZoneHeight)
			self.scrollingRate = -(topDropZoneHeight - MAX(location.y, 0)) / bottomDropZoneHeight;
		else
			self.scrollingRate = 0;
	}
}

#pragma mark UIGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer == self.panRecognizer) {
		UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;

		CGPoint point          = [pan translationInView:self.tableView];
		CGPoint location       = [pan locationInView:self.tableView];
		NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

		// The pan gesture recognizer will fail the original scrollView scroll
		// gesture, we wants to ensure we are panning left/right to enable the
		// pan gesture.
		if (fabsf(point.y) > fabsf(point.x)) {
			return NO;
		} else if (indexPath == nil) {
			return NO;
		} else if (indexPath) {
			BOOL canEditRow = [self.delegate gestureRecognizer:self canEditRowAtIndexPath:indexPath];
			return canEditRow;
		}
	} else if (gestureRecognizer == self.longPressRecognizer) {
		CGPoint location       = [gestureRecognizer locationInView:self.tableView];
		NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

		if (indexPath) {
			BOOL canMoveRow = [self.delegate gestureRecognizer:self canMoveRowAtIndexPath:indexPath];
			return canMoveRow;
		}

		return NO;
	}

	return YES;
}

#pragma mark Class method

+ (TransformableTableViewGestureRecognizer *)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate {
	TransformableTableViewGestureRecognizer *recognizer = [[TransformableTableViewGestureRecognizer alloc] init];
	recognizer.delegate  = delegate;
	recognizer.tableView = tableView;

	if ([delegate conformsToProtocol:@protocol(TransformableTableViewGestureEditingRowDelegate)]) {
		UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:recognizer action:@selector(panGestureRecognizer:)];
		[tableView addGestureRecognizer:pan];
		pan.delegate             = recognizer;
		recognizer.panRecognizer = pan;
	}

	if ([delegate conformsToProtocol:@protocol(TransformableTableViewGestureMovingRowDelegate)]) {
		UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:recognizer action:@selector(longPressGestureRecognizer:)];
		[tableView addGestureRecognizer:longPress];
		longPress.delegate             = recognizer;
		recognizer.longPressRecognizer = longPress;
	}

	return recognizer;
}

@end

@implementation UITableView (TableViewGestureDelegate)

- (TransformableTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate {
	TransformableTableViewGestureRecognizer *recognizer = [TransformableTableViewGestureRecognizer gestureRecognizerWithTableView:self delegate:delegate];
	return recognizer;
}

- (void)disableGestureTableViewWithRecognizer:(TransformableTableViewGestureRecognizer *)recognizer {
	if (recognizer.panRecognizer) {
		recognizer.panRecognizer.delegate = nil;
		[recognizer.tableView removeGestureRecognizer:recognizer.panRecognizer];
		recognizer.panRecognizer = nil;
	}

	if (recognizer.longPressRecognizer) {
		recognizer.longPressRecognizer.delegate = nil;
		[recognizer.tableView removeGestureRecognizer:recognizer.longPressRecognizer];
		recognizer.longPressRecognizer = nil;
	}

	recognizer.delegate  = nil;
	recognizer.tableView = nil;
}

@end
