#import <UIKit/UIKit.h>

typedef enum {
    TableViewCellEditingStateNone,
    TableViewCellEditingStateMiddle,
    TableViewCellEditingStateLeft,
    TableViewCellEditingStateRight,
} TableViewCellEditingState;

extern CGFloat const TableViewCommitEditingRowDefaultLength;

extern CGFloat const TableViewRowAnimationDuration;

@protocol TableViewGestureAddingRowDelegate;
@protocol TableViewGestureEditingRowDelegate;
@protocol TableViewGestureMoveRowDelegate;


@interface TableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (nonatomic, weak, readonly) UITableView *tableView;
@property (nonatomic, readonly) CGPoint translationInTableView;

+ (TableViewGestureRecognizer *)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate;

@end

#pragma mark -

@protocol TableViewGestureAddingRowDelegate <NSObject>

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSIndexPath *)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer willCreateCellAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@protocol TableViewGestureEditingRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (CGFloat)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@protocol TableViewGestureMoveRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@interface UITableView (TableViewGestureDelegate)

- (TableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate;

//- (void)reloadVisibleRowsExceptIndexPath:(NSIndexPath *)indexPath;

@end