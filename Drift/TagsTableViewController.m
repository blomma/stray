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
#import "TagTableViewCell.h"
#import <QuartzCore/QuartzCore.h>
#import "SKBounceAnimation.h"
#import "InnerShadowLayer.h"
#import "CAAnimation+Blocks.h"

static NSString *grabbedTableViewCellIdentifier  = @"grabbedTableViewCellIdentifier";
static NSString *pullDownTableViewCellIdentifier = @"pullDownTableViewCellIdentifier";

static NSInteger kEditingStateRightOffset = 260;
static NSInteger kEditingCommitLength = 60;

static NSInteger kPullingCommitHeight = 74;
static NSInteger kPullingFinishHeight = 74;

@interface TagsTableViewController ()<TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGesturePullingRowDelegate, TransformableTableViewGestureMovingRowDelegate, TagTableViewCellDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) Tag *tagInEditState;

@property (nonatomic) Tags *tags;

@property (nonatomic) NSIndexPath *transformingPullingIndexPath;
@property (nonatomic) NSIndexPath *transformingMovingIndexPath;

@property (nonatomic) UIColor *cellBackgroundColor;

@end

@implementation TagsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tags = [[Tags alloc] initWithTags:[[DataManager instance] tags]];

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:grabbedTableViewCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:pullDownTableViewCellIdentifier];
}

#pragma mark -
#pragma mark Public properties

- (UIColor *)cellBackgroundColor {
    if (!_cellBackgroundColor) {
        UIImage* background = [UIImage imageNamed:@"navy_blue"];
        _cellBackgroundColor = [UIColor colorWithPatternImage:background];
    }

    return _cellBackgroundColor;
}

#pragma mark -
#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.transformingPullingIndexPath ? (NSInteger)self.tags.count + 1 : (NSInteger)self.tags.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *tagsTableViewCellIdentifier = @"TagsTableViewCell";

    if (self.transformingPullingIndexPath && self.transformingPullingIndexPath.row == indexPath.row) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:pullDownTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.font = [UIFont fontWithName:@"Futura-Medium" size:25];
        cell.textLabel.backgroundColor = [UIColor clearColor];

        if (cell.bounds.size.height > kPullingCommitHeight * 2) {
            cell.textLabel.text = @"Close";
            cell.contentView.backgroundColor = [UIColor colorWithRed:0.843f
                                                               green:0.306f
                                                                blue:0.314f
                                                               alpha:1];
        } else if (cell.bounds.size.height >= kPullingCommitHeight) {
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
                                                               alpha:(cell.bounds.size.height / kPullingCommitHeight)];
        }

        return cell;
    } else if (self.transformingMovingIndexPath && self.transformingMovingIndexPath.row == indexPath.row) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:grabbedTableViewCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    } else {
        NSUInteger index = self.transformingPullingIndexPath ? (NSUInteger)indexPath.row - 1 : (NSUInteger)indexPath.row;
        Tag *tag = [self.tags objectAtIndex:index];
        
        TagTableViewCell *cell = (TagTableViewCell *)[tableView dequeueReusableCellWithIdentifier:tagsTableViewCellIdentifier];

        CGRect frame = cell.textFieldName.frame;
        frame.size.height = 40;
        cell.textFieldName.frame = frame;
        cell.textFieldName.text = tag.name;

        UIColor *backgroundColor = [UIColor colorWithWhite:0.075f alpha:1];
        if ([self.event.inTag isEqual:tag]) {
            backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1];
        }
        
        cell.frontView.backgroundColor = backgroundColor;

        NSString *tagName = tag.name ? tag.name : @"Fill me in";
        cell.name.text = [tagName uppercaseString];

        if ([self.tagInEditState isEqual:tag]) {
            CGPoint fromValue = cell.frontView.layer.position;
            CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + kEditingStateRightOffset, fromValue.y);
            cell.frontView.layer.position = toValue;
            
            if (!cell.backViewInnerShadowLayer) {
                InnerShadowLayer *innerShadowLayer = [self innerShadowLayerForCell:cell];
                cell.backViewInnerShadowLayer = innerShadowLayer;
                [cell.backView.layer addSublayer:innerShadowLayer];
            }

            if (!cell.layer.shadowPath) {
                [self addFrontViewShadowToCell:cell];
            }
        }

        cell.delegate = self;

        return cell;
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kPullingFinishHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Now we check if we have any cells in editstate,
    // if so we animate them back to normal state
    if (self.tagInEditState) {
        NSUInteger editStateIndex = [self.tags indexOfObject:self.tagInEditState];
        NSIndexPath *editStateIndexPath = [NSIndexPath indexPathForRow:(NSInteger)editStateIndex inSection:0];

        TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:editStateIndexPath];
        CGPoint fromValue = cell.frontView.layer.position;
        CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:^(BOOL finished) {
            [cell.backViewInnerShadowLayer removeFromSuperlayer];
            cell.backViewInnerShadowLayer = nil;

            [self removeFrontViewShadowFromCell:cell];
        }];
    }
    

    // If something is selected then something should always be deslected
    // since selection works as a toogle
    TagTableViewCell *previousSelectedCell = nil;
    if (self.event.inTag) {
        NSUInteger previousSelectedIndex = [self.tags indexOfObject:self.event.inTag];
        NSIndexPath *previousSelectedIndexPath = [NSIndexPath indexPathForRow:(NSInteger)previousSelectedIndex inSection:0];

        previousSelectedCell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:previousSelectedIndexPath];
    }

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    // Now to see if something should also be selected
    // that only happens if the current tag is different than the
    // tag being selected
    TagTableViewCell *selectedCell = nil;
    if (![self.event.inTag isEqual:tag]) {
        selectedCell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
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
#pragma mark TransformableTableViewGesturePullingRowDelegate

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer heightForCommitAddingRowAtIndexPath:(NSIndexPath *)indexPath {
    return kPullingCommitHeight;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsAddRowAtIndexPath:(NSIndexPath *)indexPath {
    self.transformingPullingIndexPath = indexPath;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCommitRowAtIndexPath:(NSIndexPath *)indexPath {
    self.transformingPullingIndexPath = nil;
    Tag *tag = [[DataManager instance] createTag];

    [self.tags insertObject:tag atIndex:(NSUInteger)indexPath.row];

    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsDiscardRowAtIndexPath:(NSIndexPath *)indexPath {
    self.transformingPullingIndexPath = nil;

    UITableViewCell *cell = [gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

    if (cell.frame.size.height > kPullingCommitHeight * 2) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark TagTableViewCellDelegate

- (void)cell:(TagTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    [[DataManager instance] deleteTag:tag];

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:^(BOOL finished) {
        [cell.backViewInnerShadowLayer removeFromSuperlayer];
        cell.backViewInnerShadowLayer = nil;

        [self removeFrontViewShadowFromCell:cell];
    }];

    self.tagInEditState = nil;

    [self.tags removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

- (void)cell:(TagTableViewCell *)cell didChangeTagName:(NSString *)name {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    tag.name = name;

    cell.name.text = [name uppercaseString];

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:^(BOOL finished) {
        [cell.backViewInnerShadowLayer removeFromSuperlayer];
        cell.backViewInnerShadowLayer = nil;

        [self removeFrontViewShadowFromCell:cell];
    }];

    self.tagInEditState = nil;
}

#pragma mark -
#pragma mark TransformableTableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        return;
    }

    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.frontView.layer removeAllAnimations];

    cell.backView.backgroundColor = self.cellBackgroundColor;
    if (!cell.backViewInnerShadowLayer) {
        InnerShadowLayer *innerShadowLayer = [self innerShadowLayerForCell:cell];
        cell.backViewInnerShadowLayer = innerShadowLayer;
        [cell.backView.layer addSublayer:innerShadowLayer];
    }

    if (!cell.layer.shadowPath) {
        [self addFrontViewShadowToCell:cell];
    }

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

    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    NSInteger xOffset = indexOfTagInEditState == (NSUInteger)indexPath.row ? kEditingStateRightOffset : 0;

    CGPoint point = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + gestureRecognizer.translationInTableView.x + xOffset, cell.frontView.layer.position.y);
    cell.frontView.layer.position = point;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        return;
    }

    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    if (state == TransformableTableViewCellEditingStateRight && !self.tagInEditState) {
        CGPoint fromValue = cell.frontView.layer.position;
        CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + kEditingStateRightOffset, fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];

        self.tagInEditState = [self.tags objectAtIndex:indexPath.row];
    } else {
        CGPoint fromValue = cell.frontView.layer.position;
        CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:^(BOOL finished) {
            [cell.backViewInnerShadowLayer removeFromSuperlayer];
            cell.backViewInnerShadowLayer = nil;

            [self removeFrontViewShadowFromCell:cell];
        }];

        self.tagInEditState = nil;
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:^(BOOL finished) {
        [cell.backViewInnerShadowLayer removeFromSuperlayer];
        cell.backViewInnerShadowLayer = nil;

        [self removeFrontViewShadowFromCell:cell];
    }];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    // if this indexPath is in a edit state then return 0 else return normal
    return indexPath.row == (NSInteger)indexOfTagInEditState ? 0 : kEditingCommitLength;
}

#pragma mark -
#pragma mark TransformableTableViewGestureMovingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsCreatePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.transformingMovingIndexPath = indexPath;

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsMoveRowAtIndexPath:(NSIndexPath *)atIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    self.transformingMovingIndexPath = toIndexPath;

    [self.tags moveObjectAtIndex:(NSUInteger)atIndexPath.row toIndex:(NSUInteger)toIndexPath.row];

    [self.tableView beginUpdates];

    [self.tableView deleteRowsAtIndexPaths:@[atIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView insertRowsAtIndexPaths:@[toIndexPath] withRowAnimation:UITableViewRowAnimationFade];

    [self.tableView endUpdates];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer needsReplacePlaceholderForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.transformingMovingIndexPath = nil;

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark Private methods

- (InnerShadowLayer *)innerShadowLayerForCell:(TagTableViewCell *)cell {
    InnerShadowLayer *innerShadowLayer = [InnerShadowLayer layer];
    innerShadowLayer.frame = cell.backView.frame;
    innerShadowLayer.shadowRadius = 2;
    innerShadowLayer.shadowOpacity = 0.7f;

    return innerShadowLayer;
}

- (void)addFrontViewShadowToCell:(TagTableViewCell *)cell {
    cell.frontView.layer.shadowColor = [[UIColor colorWithWhite:0 alpha:1] CGColor];
    cell.frontView.layer.masksToBounds = NO;
    cell.frontView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    cell.frontView.layer.shadowRadius = 2;
    cell.frontView.layer.shadowOpacity = 0.7f;
    CGRect shadowFrame = CGRectInset(cell.frontView.bounds, 0.0f, 7.0f);
    cell.frontView.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowFrame].CGPath;
}

- (void)removeFrontViewShadowFromCell:(TagTableViewCell *)cell {
    cell.frontView.layer.shadowColor = nil;
    cell.frontView.layer.masksToBounds = YES;
    cell.frontView.layer.shadowRadius = 0;
    cell.frontView.layer.shadowOpacity = 0;
    cell.frontView.layer.shadowPath = nil;
}

- (void)animateBounceOnLayer:(CALayer *)layer fromPoint:(CGPoint)from toPoint:(CGPoint)to withDuration:(CFTimeInterval)duration completion:(void (^)(BOOL finished))completion{
    static NSString *keyPath = @"position";

	SKBounceAnimation *positionAnimation = [SKBounceAnimation animationWithKeyPath:keyPath];
	positionAnimation.fromValue = [NSValue valueWithCGPoint:from];
	positionAnimation.toValue = [NSValue valueWithCGPoint:to];
	positionAnimation.duration = duration;
	positionAnimation.numberOfBounces = 4;
    positionAnimation.completion = completion;

	[layer addAnimation:positionAnimation forKey:@"someKey2"];
	[layer setValue:[NSValue valueWithCGPoint:to] forKeyPath:keyPath];
}

@end
