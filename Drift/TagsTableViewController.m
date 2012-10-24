//
//  TagsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagsTableViewController.h"
#import "Tags.h"
#import "DataManager.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "TransformableTableViewCell.h"
#import "UITableView+Change.h"
#import <QuartzCore/QuartzCore.h>
#import "SKBounceAnimation.h"

static NSString *grabbedTableViewCellIdentifier  = @"grabbedTableViewCellIdentifier";
static NSString *pullDownTableViewCellIdentifier = @"pullDownTableViewCellIdentifier";

static NSInteger kEditStateRightOffset = 260;
static NSInteger kEditCommitLength = 60;

static NSInteger kAddingCommitHeight = 74;
static NSInteger kAddingFinishHeight = 74;

@interface TagsTableViewController ()<TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGestureAddingRowDelegate, TransformableTableViewGestureMoveRowDelegate, TableViewCellEditingRowDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic) id grabbedObject;

@property (nonatomic) Tag *tagInEditState;

@property (nonatomic) Tags *tags;

@end

@implementation TagsTableViewController

#pragma mark -
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tags = [[Tags alloc] initWithTags:[[DataManager instance] tags]];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:grabbedTableViewCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:pullDownTableViewCellIdentifier];
}

#pragma mark -
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
        cell.backView.shadowRadius = 2;
        cell.backView.shadowOpacity = 0.7f;

        // Left/Right edge shadow
        cell.frontView.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:1] CGColor];
        cell.frontView.layer.masksToBounds = NO;
        cell.frontView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        cell.frontView.layer.shadowRadius = 2;
        cell.frontView.layer.shadowOpacity = 0.7f;
        CGRect shadowFrame = CGRectInset(cell.frontView.bounds, 0.0f, 7.0f);
        cell.frontView.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowFrame].CGPath;

        CGRect frame = cell.textFieldName.frame;
        frame.size.height = 40;
        cell.textFieldName.frame = frame;
        cell.textFieldName.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:0.923 alpha:1.000];
        cell.textFieldName.text = [object name];

        UIColor *backgroundColor = [UIColor colorWithWhite:0.075f alpha:1];
        if ([self.event.inTag isEqual:object]) {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1];
        }
        
        cell.frontView.backgroundColor = backgroundColor;

        NSString *tagName = [object name] ? [object name] : @"Fill me in";
        cell.name.text = [tagName uppercaseString];

        cell.delegate = self;

        return cell;
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kAddingFinishHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Now we check if we have any cells in editstate,
    // if so we animate them back to normal state
    if (self.tagInEditState) {
        NSUInteger editStateIndex = [self.tags indexOfObject:self.tagInEditState];
        NSIndexPath *editStateIndexPath = [NSIndexPath indexPathForRow:(NSInteger)editStateIndex inSection:0];

        TransformableTableViewCell *cell = (TransformableTableViewCell *)[self.tableView cellForRowAtIndexPath:editStateIndexPath];
        CGPoint fromValue = cell.frontView.layer.position;
        CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f];
    }
    

    // If something is selected then something should always be deslected
    // since selection works as a toogle
    TransformableTableViewCell *previousSelectedCell = nil;
    if (self.event.inTag) {
        NSUInteger previousSelectedIndex = [self.tags indexOfObject:self.event.inTag];
        NSIndexPath *previousSelectedIndexPath = [NSIndexPath indexPathForRow:(NSInteger)previousSelectedIndex inSection:0];

        previousSelectedCell = (TransformableTableViewCell *)[self.tableView cellForRowAtIndexPath:previousSelectedIndexPath];
    }

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    // Now to see if something should also be selected
    // that only happens if the current tag is different than the
    // tag being selected
    TransformableTableViewCell *selectedCell = nil;
    if (![self.event.inTag isEqual:tag]) {
        selectedCell = (TransformableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    }

    [UIView animateWithDuration:0.2 animations:^{
        if (previousSelectedCell) {
            previousSelectedCell.frontView.backgroundColor = [UIColor colorWithWhite:0.075f alpha:1];
        }

        if (selectedCell) {
            selectedCell.frontView.backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.000];
        }
    } completion:^(BOOL finished) {
        self.event.inTag = [self.event.inTag isEqual:tag] ? nil : tag;
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

#pragma mark -
#pragma mark TableViewGestureAddingRowDelegate

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return kAddingCommitHeight;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    NSSet *changes = [self.tags insertObject:pullDownTableViewCellIdentifier atIndex:(NSUInteger)indexPath.row];
    [self.tableView updateWithChanges:changes];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [[DataManager instance] createTag];

    NSSet *changes = [self.tags replaceObjectAtIndex:(NSUInteger)indexPath.row withObject:tag];

    [self.tableView updateWithChanges:changes];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
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

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f];

    self.tagInEditState = nil;

    NSSet *changes = [self.tags removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self.tableView updateWithChanges:changes];
}

- (void)cell:(TransformableTableViewCell *)cell didChangeTagName:(NSString *)name {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    tag.name = name;

    cell.name.text = [name uppercaseString];

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f];

    self.tagInEditState = nil;
}

#pragma mark -
#pragma mark TableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        return;
    }

    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.frontView.layer removeAllAnimations];

    // If we have a cell in editstate and it is not this cell then cancel it
    if (self.tagInEditState && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        NSIndexPath *indexPathInEditState = [NSIndexPath indexPathForRow:(NSInteger)indexOfTagInEditState inSection:0];
        [self gestureRecognizer:gestureRecognizer cancelEditingState:state forRowAtIndexPath:indexPathInEditState];
        self.tagInEditState = nil;
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        return;
    }

    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    NSInteger xOffset = indexOfTagInEditState == (NSUInteger)indexPath.row ? kEditStateRightOffset : 0;
    cell.frontView.frame = CGRectOffset(cell.frontView.bounds, gestureRecognizer.translationInTableView.x + xOffset, 0);
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        return;
    }

    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    if (state == TransformableTableViewCellEditingStateRight && !self.tagInEditState) {
        CGPoint fromValue = cell.frontView.layer.position;
        CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + kEditStateRightOffset, fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f];

        self.tagInEditState = [self.tags objectAtIndex:indexPath.row];
    } else {
        CGPoint fromValue = cell.frontView.layer.position;
        CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f];

        self.tagInEditState = nil;
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TransformableTableViewCell *cell = (TransformableTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    // if this indexPath is in a edit state then return 0 else return normal
    return indexPath.row == (NSInteger)indexOfTagInEditState ? 0 : kEditCommitLength;
}

#pragma mark -
#pragma mark TableViewGestureMoveRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.grabbedObject = [self.tags objectAtIndex:indexPath.row];

    NSSet *changes = [self.tags replaceObjectAtIndex:(NSUInteger)indexPath.row withObject:grabbedTableViewCellIdentifier];
    [self.tableView updateWithChanges:changes];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)atIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSUInteger atIndex = (NSUInteger)atIndexPath.row;
    NSUInteger toIndex = (NSUInteger)toIndexPath.row;

    NSSet *changes = [self.tags moveObjectAtIndex:atIndex toIndex:toIndex];
    [self.tableView updateWithChanges:changes];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSSet *changes = [self.tags replaceObjectAtIndex:(NSUInteger)indexPath.row withObject:self.grabbedObject];
    [self.tableView updateWithChanges:changes];

    self.grabbedObject = nil;
}

#pragma mark -
#pragma mark Private methods

- (void)animateBounceOnLayer:(CALayer *)layer fromPoint:(CGPoint)from toPoint:(CGPoint)to withDuration:(CFTimeInterval)duration{
	SKBounceAnimation *positionAnimation = [SKBounceAnimation animationWithKeyPath:@"position"];
	positionAnimation.fromValue = [NSValue valueWithCGPoint:from];
	positionAnimation.toValue = [NSValue valueWithCGPoint:to];
	positionAnimation.duration = duration;
	positionAnimation.numberOfBounces = 4;

	[layer addAnimation:positionAnimation forKey:@"someKey2"];
	[layer setValue:[NSValue valueWithCGPoint:to] forKeyPath:@"position"];
}

@end
