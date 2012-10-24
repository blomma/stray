#import "TransformableTableViewGestureRecognizer.h"
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(uint16_t, TableViewGestureRecognizerState) {
    TableViewGestureRecognizerStateNone,
    TableViewGestureRecognizerStateDragging,
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
@property (nonatomic, weak) id <TransformableTableViewGestureAddingRowDelegate, TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGestureMoveRowDelegate> delegate;
@property (nonatomic, weak) id <UITableViewDelegate> tableViewDelegate;

// Adding
@property (nonatomic) CGFloat addingRowHeight;

// Editing
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic) TransformableTableViewCellEditingState editingCellState;

// Moving
@property (nonatomic) UILongPressGestureRecognizer  *longPressRecognizer;
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
    CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.scrollingRate);
    if (newOffset.y < 0) {
        newOffset.y = 0;
    } else if (self.tableView.contentSize.height < self.tableView.frame.size.height) {
        newOffset = currentOffset;
    } else if (newOffset.y > self.tableView.contentSize.height - self.tableView.frame.size.height) {
        newOffset.y = self.tableView.contentSize.height - self.tableView.frame.size.height;
    } else {
    }

    if (currentOffset.y != newOffset.y) {
        [self.tableView setContentOffset:newOffset];

        UIImageView *cellSnapshotView = (id)[self.tableView viewWithTag:kCellSnapShotTag];
        cellSnapshotView.center = CGPointMake(self.tableView.center.x, location.y);
    }
}

#pragma mark Logic

- (void)commitOrDiscardCell {
    if (self.transformIndexPath) {
        UITableViewCell *cell = (UITableViewCell *)[self.tableView cellForRowAtIndexPath:self.transformIndexPath];

        CGFloat commitingCellHeight = self.tableView.rowHeight;
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:heightForCommitAddingRowAtIndexPath:)]) {
            commitingCellHeight = [self.delegate gestureRecognizer:self
                                 heightForCommitAddingRowAtIndexPath:self.transformIndexPath];
        }

        if (cell.frame.size.height > commitingCellHeight * 2 || cell.frame.size.height < commitingCellHeight) {
            [self.delegate gestureRecognizer:self needsDiscardRowAtIndexPath:self.transformIndexPath];
        } else {
            [self.delegate gestureRecognizer:self needsCommitRowAtIndexPath:self.transformIndexPath];
        }

        self.transformIndexPath = nil;
    }

    self.state = TableViewGestureRecognizerStateNone;
}

#pragma mark Action

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan && [recognizer numberOfTouches] > 0) {
        CGPoint translation = [recognizer translationInView:self.tableView];
        self.translationInTableView = translation;

        NSIndexPath *indexPath = self.transformIndexPath;
        if (!indexPath) {
            CGPoint location = [recognizer locationOfTouch:0 inView:self.tableView];

            indexPath = [self.tableView indexPathForRowAtPoint:location];
            self.transformIndexPath = indexPath;
        }

        self.editingCellState = translation.x >= 0 ? TransformableTableViewCellEditingStateRight : TransformableTableViewCellEditingStateLeft;
        self.state = TableViewGestureRecognizerStatePanning;

        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didEnterEditingState:forRowAtIndexPath:)]) {
            [self.delegate gestureRecognizer:self didEnterEditingState:self.editingCellState forRowAtIndexPath:indexPath];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        NSIndexPath *indexPath = self.transformIndexPath;
        CGPoint translation = [recognizer translationInView:self.tableView];
        self.translationInTableView = translation;

        CGFloat commitEditingLength = kCommitEditingRowDefaultLength;
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:lengthForCommitEditingRowAtIndexPath:)]) {
            commitEditingLength = [self.delegate gestureRecognizer:self lengthForCommitEditingRowAtIndexPath:indexPath];
        }

        self.editingCellState = translation.x > 0 ? TransformableTableViewCellEditingStateRight : TransformableTableViewCellEditingStateLeft;

        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didChangeEditingState:forRowAtIndexPath:)]) {
            [self.delegate gestureRecognizer:self didChangeEditingState:self.editingCellState forRowAtIndexPath:indexPath];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSIndexPath *indexPath = self.transformIndexPath;

        // Removes addingIndexPath before updating then tableView will be able
        // to determine correct table row height
        self.transformIndexPath = nil;

        CGPoint translation = [recognizer translationInView:self.tableView];

        CGFloat commitEditingLength = kCommitEditingRowDefaultLength;
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:lengthForCommitEditingRowAtIndexPath:)]) {
            commitEditingLength = [self.delegate gestureRecognizer:self lengthForCommitEditingRowAtIndexPath:indexPath];
        }

        if (fabsf(translation.x) >= commitEditingLength) {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizer:commitEditingState:forRowAtIndexPath:)]) {
                [self.delegate gestureRecognizer:self commitEditingState:self.editingCellState forRowAtIndexPath:indexPath];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizer:cancelEditingState:forRowAtIndexPath:)]) {
                [self.delegate gestureRecognizer:self cancelEditingState:self.editingCellState forRowAtIndexPath:indexPath];
            }
        }

        self.editingCellState = TransformableTableViewCellEditingStateNone;
        self.state = TableViewGestureRecognizerStateNone;
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

            snapShotView = [[UIImageView alloc] initWithImage:cellImage];
            snapShotView.tag = kCellSnapShotTag;

            [self.tableView addSubview:snapShotView];

            CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
            snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
        }

        // Make a zoom in effect for the cell
        [UIView animateWithDuration:kAddingAnimationDuration animations:^{
            snapShotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            snapShotView.center = CGPointMake(self.tableView.center.x, location.y);
            snapShotView.alpha = 0.65;
        }];

        [self.delegate gestureRecognizer:self needsCreatePlaceholderForRowAtIndexPath:indexPath];
        self.transformIndexPath = indexPath;

        // Start timer to prep	are for auto scrolling
        self.movingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTable) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.movingTimer forMode:NSDefaultRunLoopMode];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        // While long press ends, we remove the snapshot imageView

        __block __weak UIImageView *snapShotView = (UIImageView *)[self.tableView viewWithTag:kCellSnapShotTag];
        __block __weak TransformableTableViewGestureRecognizer *weakSelf = self;

        // We use self.addingIndexPath directly to make sure we dropped on a valid indexPath
        // which we've already ensure while UIGestureRecognizerStateChanged
        __block __weak NSIndexPath *weakAddingIndexPath = self.transformIndexPath;

        // Stop timer
        [self.movingTimer invalidate];
        self.movingTimer = nil;
        self.scrollingRate = 0;

        [UIView animateWithDuration:kAddingAnimationDuration
                         animations:^{
                             CGRect rect = [weakSelf.tableView rectForRowAtIndexPath:weakAddingIndexPath];
                             snapShotView.transform = CGAffineTransformIdentity;    // restore the transformed value
                             snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
                             snapShotView.alpha = 1;
                         } completion:^(BOOL finished) {
                             [snapShotView removeFromSuperview];

                             [weakSelf.delegate gestureRecognizer:weakSelf needsReplacePlaceholderForRowAtIndexPath:weakAddingIndexPath];

                             // Update state and clear instance variables
                             weakSelf.transformIndexPath = nil;
                             weakSelf.state = TableViewGestureRecognizerStateNone;
                         }];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        NSIndexPath *indexPath  = [self.tableView indexPathForRowAtPoint:location];

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
        CGFloat bottomDiff = location.y - (rect.size.height - bottomDropZoneHeight);
        if (bottomDiff > 0) {
            self.scrollingRate = bottomDiff / (bottomDropZoneHeight / 1);
        } else if (location.y <= topDropZoneHeight) {
            self.scrollingRate = -(topDropZoneHeight - MAX(location.y, 0)) / bottomDropZoneHeight;
        } else {
            self.scrollingRate = 0;
        }
    }
}

#pragma mark UIGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panRecognizer) {
        if (![self.delegate conformsToProtocol:@protocol(TransformableTableViewGestureEditingRowDelegate)]) {
            return NO;
        }

        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;

        CGPoint point = [pan translationInView:self.tableView];
        CGPoint location = [pan locationInView:self.tableView];
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
        CGPoint location = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

        if (indexPath && [self.delegate conformsToProtocol:@protocol(TransformableTableViewGestureMoveRowDelegate)]) {
            BOOL canMoveRow = [self.delegate gestureRecognizer:self canMoveRowAtIndexPath:indexPath];
            return canMoveRow;
        }

        return NO;
    }

    return YES;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:self.transformIndexPath]
        && self.state == TableViewGestureRecognizerStateDragging) {
        // While state is in pinching or dragging mode, we intercept the row height
        // For Moving state, we leave our real delegate to determine the actual height
        return MAX(1, self.addingRowHeight);
    }

    CGFloat normalCellHeight = aTableView.rowHeight;
    if ([self.tableViewDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        normalCellHeight = [self.tableViewDelegate tableView:aTableView heightForRowAtIndexPath:indexPath];
    }

    return normalCellHeight;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (![self.delegate conformsToProtocol:@protocol(TransformableTableViewGestureAddingRowDelegate)]) {
        if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
            [self.tableViewDelegate scrollViewDidScroll:scrollView];
        }

        return;
    }

    // We try to create a new cell when the user tries to drag the content to and offset of negative value
    if (scrollView.contentOffset.y < 0) {
        // Here we make sure we're not conflicting with the pinch event,
        // ! scrollView.isDecelerating is to detect if user is actually
        // touching on our scrollView, if not, we should assume the scrollView
        // needed not to be adding cell
        if (!self.transformIndexPath && self.state == TableViewGestureRecognizerStateNone && !scrollView.isDecelerating) {
            self.state = TableViewGestureRecognizerStateDragging;

            self.transformIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];

            [self.delegate gestureRecognizer:self needsAddRowAtIndexPath:self.transformIndexPath];
            self.addingRowHeight = fabsf(scrollView.contentOffset.y);
        }
    }

    // Check if addingIndexPath not exists, we don't want to
    // alter the contentOffset of our scrollView
    if (self.transformIndexPath && self.state == TableViewGestureRecognizerStateDragging) {
        self.addingRowHeight += scrollView.contentOffset.y * -1;

        [self.tableView reloadData];
        [scrollView setContentOffset:CGPointZero];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ( ! [self.delegate conformsToProtocol:@protocol(TransformableTableViewGestureAddingRowDelegate)]) {
        if ([self.tableViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
            [self.tableViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
        }
        return;
    }

    if (self.state == TableViewGestureRecognizerStateDragging) {
        self.state = TableViewGestureRecognizerStateNone;
        [self commitOrDiscardCell];
    }
}

#pragma mark NSProxy

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:self.tableViewDelegate];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [(NSObject *)self.tableViewDelegate methodSignatureForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    NSAssert(self.tableViewDelegate != nil, @"self.tableViewDelegate should not be nil, assign your tableView.delegate before enabling gestureRecognizer", nil);
    if ([self.tableViewDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    return [[self class] instancesRespondToSelector:aSelector];
}

#pragma mark Class method

+ (TransformableTableViewGestureRecognizer *)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate {
    TransformableTableViewGestureRecognizer *recognizer = [[TransformableTableViewGestureRecognizer alloc] init];
    recognizer.delegate          = (id)delegate;
    recognizer.tableView         = tableView;
    recognizer.tableViewDelegate = tableView.delegate;     // Assign the delegate before chaning the tableView's delegate
    tableView.delegate           = recognizer;

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:recognizer action:@selector(panGestureRecognizer:)];
    [tableView addGestureRecognizer:pan];
    pan.delegate             = recognizer;
    recognizer.panRecognizer = pan;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:recognizer action:@selector(longPressGestureRecognizer:)];
    [tableView addGestureRecognizer:longPress];
    longPress.delegate             = recognizer;
    recognizer.longPressRecognizer = longPress;

    return recognizer;
}

@end


@implementation UITableView (TableViewGestureDelegate)

- (TransformableTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate {
    TransformableTableViewGestureRecognizer *recognizer = [TransformableTableViewGestureRecognizer gestureRecognizerWithTableView:self delegate:delegate];
    return recognizer;
}

@end