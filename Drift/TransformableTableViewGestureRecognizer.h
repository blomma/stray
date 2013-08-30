// 
//  TransformableTableViewGestureRecognizer.h
//  stray
//  
//  Created by Mikael Hultgren on 2013-07-22.
//  Copyright 2013 Artsoftheinsane. All rights reserved.
// 

typedef NS_ENUM (uint16_t, TransformableTableViewCellEditingDirection) {
	None,
	Left,
	Right
};

@protocol TransformableTableViewGestureEditingRowDelegate;
@protocol TransformableTableViewGestureMovingRowDelegate;

@interface TransformableTableViewGestureRecognizer : NSObject <UITableViewDelegate>

@property (nonatomic, weak, readonly) UITableView *tableView;
@property (nonatomic, readonly) CGPoint translationInTableView;

+ (TransformableTableViewGestureRecognizer *)gestureRecognizerWithTableView:(UITableView *)tableView delegate:(id)delegate;

@end

#pragma mark -

@protocol TransformableTableViewGestureEditingRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingDirection)state forRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol TransformableTableViewGestureMovingRowDelegate <NSObject>

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;
- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface UITableView (TableViewGestureDelegate)

- (TransformableTableViewGestureRecognizer *)enableGestureTableViewWithDelegate:(id)delegate;
- (void)disableGestureTableViewWithRecognizer:(TransformableTableViewGestureRecognizer *)recognizer;

@end
