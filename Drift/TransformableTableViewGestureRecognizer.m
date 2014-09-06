#import "TransformableTableViewGestureRecognizer.h"

#import <QuartzCore/QuartzCore.h>

static CGFloat kCommitEditingRowDefaultLength = 80;

@interface TransformableTableViewGestureRecognizer () <UIGestureRecognizerDelegate>

// public properties
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic) CGPoint translationInTableView;
@property (nonatomic) CGPoint velocity;

// private properties
@property (nonatomic, weak) id <TransformableTableViewGestureEditingRowDelegate> delegate;

// Editing
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic) TransformableTableViewCellEditingState editingCellState;

@property (nonatomic) NSIndexPath *transformIndexPath;

@end

@implementation TransformableTableViewGestureRecognizer

#pragma mark Action

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan && [recognizer numberOfTouches] > 0) {
        CGPoint translation = [recognizer translationInView:self.tableView];
        self.translationInTableView = translation;
        self.velocity = [recognizer velocityInView:self.tableView];

        NSIndexPath *indexPath = self.transformIndexPath;
        if (!indexPath) {
            CGPoint location = [recognizer locationOfTouch:0 inView:self.tableView];

            indexPath               = [self.tableView indexPathForRowAtPoint:location];
            self.transformIndexPath = indexPath;
        }

        self.editingCellState = translation.x >= 0 ? TransformableTableViewCellEditingStateRight : TransformableTableViewCellEditingStateLeft;

        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didEnterEditingState:forRowAtIndexPath:)]) {
            [self.delegate gestureRecognizer:self
                        didEnterEditingState:self.editingCellState
                           forRowAtIndexPath:indexPath];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        NSIndexPath *indexPath = self.transformIndexPath;
        CGPoint translation    = [recognizer translationInView:self.tableView];
        self.translationInTableView = translation;
        self.velocity = [recognizer velocityInView:self.tableView];

        self.editingCellState = translation.x > 0 ? TransformableTableViewCellEditingStateRight : TransformableTableViewCellEditingStateLeft;

        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:didChangeEditingState:forRowAtIndexPath:)]) {
            [self.delegate gestureRecognizer:self didChangeEditingState:self.editingCellState forRowAtIndexPath:indexPath];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSIndexPath *indexPath = self.transformIndexPath;

        self.transformIndexPath = nil;

        CGPoint translation = [recognizer translationInView:self.tableView];
        self.translationInTableView = translation;
        self.velocity = [recognizer velocityInView:self.tableView];

        CGFloat commitEditingLength = kCommitEditingRowDefaultLength;
        if ([self.delegate respondsToSelector:@selector(gestureRecognizer:lengthForCommitEditingRowAtIndexPath:)]) {
            commitEditingLength = [self.delegate gestureRecognizer:self lengthForCommitEditingRowAtIndexPath:indexPath];
        }

        if (fabs(translation.x) >= commitEditingLength) {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizer:commitEditingState:forRowAtIndexPath:)]) {
                [self.delegate gestureRecognizer:self commitEditingState:self.editingCellState forRowAtIndexPath:indexPath];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizer:cancelEditingState:forRowAtIndexPath:)]) {
                [self.delegate gestureRecognizer:self cancelEditingState:self.editingCellState forRowAtIndexPath:indexPath];
            }
        }

        self.editingCellState = TransformableTableViewCellEditingStateNone;
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
        if (fabs(point.y) > fabs(point.x)) {
            return NO;
        } else if (indexPath == nil) {
            return NO;
        } else if (indexPath) {
            BOOL canEditRow = [self.delegate gestureRecognizer:self canEditRowAtIndexPath:indexPath];
            return canEditRow;
        }
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

    recognizer.delegate  = nil;
    recognizer.tableView = nil;
}

@end
