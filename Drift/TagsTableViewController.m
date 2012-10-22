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
#import <QuartzCore/QuartzCore.h>

static NSString *grabbedTableViewCellIdentifier  = @"grabbedTableViewCellIdentifier";
static NSString *pullDownTableViewCellIdentifier = @"pullDownTableViewCellIdentifier";

static NSInteger kEditStateRightOffset = 260;
static NSInteger kEditCommitLength = 60;

static NSInteger kAddingCommitHeight = 74;
static NSInteger kAddingFinishHeight = 74;

@interface TagsTableViewController ()<TableViewGestureEditingRowDelegate, TableViewGestureAddingRowDelegate, TableViewGestureMoveRowDelegate, TableViewCellEditingRowDelegate>

@property (nonatomic) TableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic) id grabbedObject;
@property (nonatomic) NSIndexPath *indexPathInEditState;

@property (nonatomic) Tags *tags;

@end

@implementation TagsTableViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tags = [[Tags alloc] initWithTags:[[DataManager instance] tags]];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:grabbedTableViewCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:pullDownTableViewCellIdentifier];
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
    cell.name.text = [tagName uppercaseString];

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
	static NSString *tagsTableViewCellIdentifier      = @"TagsTableViewCell";

    id object = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    if ([object isKindOfClass:[NSString class]] && [object isEqualToString:pullDownTableViewCellIdentifier] && indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pullDownTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
        cell.textLabel.backgroundColor = [UIColor clearColor];

        if (cell.frame.size.height > kAddingCommitHeight * 2) {
            cell.textLabel.text = @"Close";
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.843f
                                                               green:0.306f
                                                                blue:0.314f
                                                               alpha:1];
        } else if (cell.frame.size.height >= kAddingCommitHeight) {
            cell.textLabel.text = @"Release to create cell...";
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.510f
                                                               green:0.784f
                                                                blue:0.431f
                                                               alpha:1];
        } else {
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.text = @"Continue Pulling...";
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.510f
                                                               green:0.784f
                                                                blue:0.431f
                                                               alpha:(cell.frame.size.height / kAddingCommitHeight)];
        }

        return cell;
    } else if ([object isKindOfClass:[NSString class]] && [object isEqualToString:grabbedTableViewCellIdentifier]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:grabbedTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    } else {
        TransformableTableViewCell *cell = (TransformableTableViewCell *)[tableView dequeueReusableCellWithIdentifier:tagsTableViewCellIdentifier];

        UIImage* background = [UIImage imageNamed:@"navy_blue"];
        cell.backView.backgroundColor = [UIColor colorWithPatternImage:background];

        cell.frontView.layer.masksToBounds = NO;
        cell.frontView.layer.shadowOffset = CGSizeMake(-1, -5);
        cell.frontView.layer.shadowRadius = 4;
        cell.frontView.layer.shadowOpacity = 0.5;
        cell.frontView.layer.shadowPath = [UIBezierPath bezierPathWithRect:cell.frontView.bounds].CGPath;

        cell.textFieldName.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:0.923 alpha:1.000];

        CGRect frame = cell.textFieldName.frame;
        frame.size.height = 40;
        cell.textFieldName.frame = frame;
        
        cell.textFieldName.text = [object name];

        cell.frontView.frame = cell.frontView.bounds;

        UIColor *backgroundColor = [UIColor colorWithWhite:0.075f alpha:1];
        
        if ([self.event.inTag isEqual:object]) {
            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
            backgroundColor = [UIColor colorWithRed:0.427f
                                              green:0.784f
                                               blue:0.992f
                                              alpha:1];
        }
        
        cell.frontView.backgroundColor = backgroundColor;

        NSString *tagName = [object name] ? [object name] : @"Fill me in";
        cell.name.text = [tagName uppercaseString];
        cell.delegate = self;


        return cell;
    }
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kAddingFinishHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    UIColor *backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.000];
    if ([self.event.inTag isEqual:tag]) {
        backgroundColor = [UIColor colorWithWhite:0.075f alpha:1];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

    self.event.inTag = [self.event.inTag isEqual:tag] ? nil : tag;

    TransformableTableViewCell *cell = (TransformableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [UIView animateWithDuration:0.1 animations:^{
        cell.frontView.backgroundColor = backgroundColor;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

#pragma mark -
#pragma mark TableViewGestureAddingRowDelegate

- (CGFloat)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return kAddingCommitHeight;
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    NSSet *changes = [self.tags insertObject:pullDownTableViewCellIdentifier atIndex:(NSUInteger)indexPath.row];
    [self.tableView updateWithChanges:changes];
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

    if (cell.frame.size.height > kAddingCommitHeight * 2) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark TableViewCellEditingRowDelegate

- (void)cell:(TransformableTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    [[DataManager instance] deleteTag:tag];

    NSSet *changes = [self.tags removeObjectAtIndex:(NSUInteger)indexPath.row];
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

    if (state == TableViewCellEditingStateLeft && cell.state == TableViewCellEditingStateNone) {
        return;
    }

    NSInteger xOffset = cell.state == TableViewCellEditingStateRight ? kEditStateRightOffset : 0;
    cell.frontView.frame = CGRectOffset(cell.frontView.bounds, gestureRecognizer.translationInTableView.x + xOffset, 0);
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    CGRect frame;
    if (cell.state == TableViewCellEditingStateLeft || cell.state == TableViewCellEditingStateRight || state == TableViewCellEditingStateLeft) {
        frame = cell.frontView.bounds;
        cell.state = TableViewCellEditingStateNone;
    } else if (state == TableViewCellEditingStateRight) {
        frame = CGRectOffset(cell.frontView.bounds, kEditStateRightOffset, 0);
        cell.state = TableViewCellEditingStateRight;
    }

    [UIView animateWithDuration:0.35
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
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
    return kEditCommitLength;
}

#pragma mark TableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [self.tags objectAtIndex:indexPath.row];

    NSSet *changes = [self.tags replaceObjectAtIndex:(NSUInteger)indexPath.row withObject:grabbedTableViewCellIdentifier];
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
