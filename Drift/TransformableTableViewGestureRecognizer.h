@import UIKit;

typedef NS_ENUM (uint16_t, TransformableTableViewCellEditingState) {
    TransformableTableViewCellEditingStateNone,
    TransformableTableViewCellEditingStateLeft,
    TransformableTableViewCellEditingStateRight
};

@protocol TransformableTableViewGestureEditingRowDelegate;

@interface TransformableTableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (nonatomic, weak, readonly) UITableView *tableView;
@property (nonatomic, readonly) CGPoint translationInTableView;
@property (nonatomic, readonly) CGPoint velocity;

+ (TransformableTableViewGestureRecognizer *)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate;

@end

#pragma mark -

@protocol TransformableTableViewGestureEditingRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface UITableView (TableViewGestureDelegate)

- (TransformableTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate;
- (void)disableGestureTableViewWithRecognizer:(TransformableTableViewGestureRecognizer *)recognizer;

@end
