//
//  TagsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagsTableViewController.h"
#import "TableViewGestureRecognizer.h"
#import "Tags.h"
#import "DataManager.h"
#import "TransformableTableViewCell.h"
#import "UITableView+Change.h"

@interface PlaceHolderAdding : NSObject
@end

@implementation PlaceHolderAdding
@end

@interface PlaceHolderGrabbed : NSObject
@end

@implementation PlaceHolderGrabbed
@end

@interface TagsTableViewController ()<TableViewGestureEditingRowDelegate, TableViewGestureAddingRowDelegate, TableViewGestureMoveRowDelegate, TableViewCellEditingRowDelegate>

@property (nonatomic) TableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic) id grabbedObject;
@property (nonatomic) NSIndexPath *indexPathInEditState;

@property (nonatomic) Tags *tags;

@end

@implementation TagsTableViewController

#define COMMITING_CREATE_CELL_HEIGHT 60
#define COMMITING_EDIT_CELL_LENGTH 60

#define NORMAL_CELL_FINISHING_HEIGHT 74

#define EDIT_STATE_LEFT_OFFSET -80
#define EDIT_STATE_RIGHT_OFFSET 260

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tags = [[Tags alloc] initWithTags:[[DataManager instance] tags]];

    // Setup your tableView.delegate and tableView.datasource,
    // then enable gesture recognition in one line.
    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"grabbedDownTableViewCellIdentifier"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"pullDownTableViewCellIdentifier"];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *tagName = textField.text;

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)self.indexPathInEditState.row];
    tag.name = tagName;

    TransformableTableViewCell *cell = (TransformableTableViewCell *)[self.tableView cellForRowAtIndexPath:self.indexPathInEditState];
    cell.name.text = tagName;

    [UIView animateWithDuration:0.55
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         cell.frontView.frame = cell.frontView.bounds;
                     } completion:nil];

    cell.state = TableViewCellEditingStateNone;
    self.indexPathInEditState = nil;
}

#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[self.tags count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *grabbedDownTableViewCellIdentifier  = @"grabbedDownTableViewCellIdentifier";
	static NSString *pullDownTableViewCellIdentifier  = @"pullDownTableViewCellIdentifier";
	static NSString *tagsTableViewCellIdentifier      = @"TagsTableViewCell";

    id object = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    if ([object isKindOfClass:[PlaceHolderAdding class]] && indexPath.row == 0) {
        DLog(@"pulldown");
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pullDownTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:30];
        cell.textLabel.backgroundColor = [UIColor clearColor];

        if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.text = @"Close";
//            cell.contentView.backgroundColor = [UIColor redColor];
        } else if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT) {
            cell.textLabel.textColor = [UIColor greenColor];
            cell.textLabel.text = @"Release to create cell...";
//            cell.contentView.backgroundColor = [UIColor greenColor];
        } else {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.text = @"Continue Pulling...";
//            cell.contentView.backgroundColor = [UIColor clearColor];
        }

        return cell;
    } else if ([object isKindOfClass:[PlaceHolderGrabbed class]]) {
        DLog(@"grabber");
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:grabbedDownTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    } else {
        DLog(@"normal");
        TransformableTableViewCell *cell = (TransformableTableViewCell *)[tableView dequeueReusableCellWithIdentifier:tagsTableViewCellIdentifier];

        UIImage* background = [UIImage imageNamed:@"low_contrast_linen"];
        cell.backView.backgroundColor = [UIColor colorWithPatternImage:background];
	
        cell.frontView.frame = cell.frontView.bounds;

        UIColor *backgroundColor = [UIColor colorWithWhite:0.333f alpha:1.000];
        if ([self.event.inTag isEqual:object]) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.000];
        }
        
        cell.frontView.backgroundColor = backgroundColor;
        cell.name.text = [(Tag *)object name];

        cell.delegate = self;

        return cell;
    }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NORMAL_CELL_FINISHING_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    UIColor *backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.000];
    if ([self.event.inTag isEqual:tag]) {
        backgroundColor = [UIColor colorWithWhite:0.333f alpha:1.000];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    TransformableTableViewCell *cell = (TransformableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2 animations:^{
        cell.frontView.backgroundColor = backgroundColor;
    }];

    self.event.inTag = [self.event.inTag isEqual:tag] ? nil : tag;

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIColor *backgroundColor = [UIColor colorWithWhite:0.333f alpha:1.000];

    TransformableTableViewCell *cell = (TransformableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2 animations:^{
        cell.frontView.backgroundColor = backgroundColor;
    }];
}

#pragma mark -
#pragma mark TableViewGestureAddingRowDelegate

- (CGFloat)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return COMMITING_CREATE_CELL_HEIGHT;
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tags insertObject:[PlaceHolderAdding new] atIndex:(NSUInteger)indexPath.row];
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [[DataManager instance] createTag];

    NSSet *changes = [self.tags replaceObjectAtIndex:(NSUInteger)indexPath.row withObject:tag];

    [self.tableView updateWithChanges:changes];
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    NSSet * changes = [self.tags removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self.tableView updateWithChanges:changes];

    if (cell.frame.size.height > COMMITING_CREATE_CELL_HEIGHT * 2) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark TableViewCellEditingRowDelegate

- (void)cell:(TransformableTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    NSUInteger index = (NSUInteger)self.indexPathInEditState.row;

    Tag *tag = [self.tags objectAtIndex:index];
    [[DataManager instance] deleteTag:tag];

    NSSet *changes = [self.tags removeObjectAtIndex:index];
    [self.tableView updateWithChanges:changes];
}

#pragma mark -
#pragma mark TableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.indexPathInEditState.row != indexPath.row || self.indexPathInEditState.section != indexPath.section) {
        [self gestureRecognizer:gestureRecognizer cancelEditingState:state forRowAtIndexPath:self.indexPathInEditState];
    }

    self.indexPathInEditState = indexPath;
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    NSInteger xOffset = 0;
    if (cell.state == TableViewCellEditingStateLeft) {
        xOffset = EDIT_STATE_LEFT_OFFSET;
    } else if (cell.state == TableViewCellEditingStateRight) {
        xOffset = EDIT_STATE_RIGHT_OFFSET;
    }

    cell.frontView.frame = CGRectOffset(cell.frontView.bounds, gestureRecognizer.translationInTableView.x + xOffset, 0);
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    CGRect frame;
    if (cell.state == TableViewCellEditingStateLeft || cell.state == TableViewCellEditingStateRight) {
        frame = cell.frontView.bounds;
        cell.state = TableViewCellEditingStateNone;
    } else if (state == TableViewCellEditingStateLeft) {
        frame = CGRectOffset(cell.frontView.bounds, EDIT_STATE_LEFT_OFFSET, 0);
        cell.state = TableViewCellEditingStateLeft;
    } else if (state == TableViewCellEditingStateRight) {
        frame = CGRectOffset(cell.frontView.bounds, EDIT_STATE_RIGHT_OFFSET, 0);
        cell.state = TableViewCellEditingStateRight;
    }

    [UIView animateWithDuration:0.35
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         cell.frontView.frame = frame;
                     } completion:nil];
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    [UIView animateWithDuration:0.55
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         cell.frontView.frame = cell.frontView.bounds;
                     } completion:nil];

    cell.state = TableViewCellEditingStateNone;
    self.indexPathInEditState = nil;
}

- (CGFloat)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return COMMITING_EDIT_CELL_LENGTH;
}

#pragma mark TableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [self.tags objectAtIndex:indexPath.row];

    NSSet *changes = [self.tags replaceObjectAtIndex:(NSUInteger)indexPath.row withObject:[PlaceHolderGrabbed new]];
    [self.tableView updateWithChanges:changes];
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)atIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSUInteger atIndex = (NSUInteger)atIndexPath.row;
    NSUInteger toIndex = (NSUInteger)toIndexPath.row;

    NSSet *changes = [self.tags moveObjectAtIndex:atIndex toIndex:toIndex];
    [self.tableView updateWithChanges:changes];
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSSet *changes = [self.tags replaceObjectAtIndex:(NSUInteger)indexPath.row withObject:self.grabbedObject];
    [self.tableView updateWithChanges:changes];

    self.grabbedObject = nil;
}

@end
