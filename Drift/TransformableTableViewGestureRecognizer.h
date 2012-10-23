#import <UIKit/UIKit.h>

typedef NS_ENUM(uint16_t, TransformableTableViewCellEditingState) {
    TransformableTableViewCellEditingStateNone,
    TransformableTableViewCellEditingStateLeft,
    TransformableTableViewCellEditingStateRight
};

@protocol TransformableTableViewGestureAddingRowDelegate;
@protocol TransformableTableViewGestureEditingRowDelegate;
@protocol TransformableTableViewGestureMoveRowDelegate;

@interface TransformableTableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (nonatomic, weak, readonly) UITableView *tableView;
@property (nonatomic, readonly) CGPoint translationInTableView;

+ (TransformableTableViewGestureRecognizer *)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate;

@end

#pragma mark -

@protocol TransformableTableViewGestureAddingRowDelegate <NSObject>

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSIndexPath *)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer willCreateCellAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@protocol TransformableTableViewGestureEditingRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@protocol TransformableTableViewGestureMoveRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface UITableView (TableViewGestureDelegate)

- (TransformableTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate;

@end