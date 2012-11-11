//
//  TagsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagsTableViewController.h"

#import "Tags.h"
#import "DataRepository.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "TagTableViewCell.h"
#import "SKBounceAnimation.h"
#import "InnerShadowLayer.h"
#import "CAAnimation+Blocks.h"
#import "UIScrollView+SVPulling.h"

@interface TagsTableViewController ()<TransformableTableViewGestureEditingRowDelegate, TransformableTableViewGestureMovingRowDelegate, TagTableViewCellDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;

@property (nonatomic) Tag *tagInEditState;
@property (nonatomic, weak) Tags *tags;

@property (nonatomic) NSIndexPath *transformingMovingIndexPath;

@property (nonatomic) NSInteger editingStateRightOffset;
@property (nonatomic) NSInteger editingCommitLength;

@end

@implementation TagsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.editingStateRightOffset = 260;
    self.editingCommitLength     = 60;

    self.tags = [DataRepository instance].tags;

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"grabbedTableViewCellIdentifier"];

    __block __weak TagsTableViewController *weakSelf = self;
    __block __weak Tags *weakTags                    = self.tags;

    [self.tableView addPullingWithActionHandler:^(SVPullingState state, CGFloat height) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            if (state == SVPullingStateTriggeredAdd) {
                [weakSelf.tableView beginUpdates];

                Tag *tag = [[DataRepository instance] createTag];
                [weakTags insertObject:tag atIndex:0];

                [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];

                [weakSelf.tableView endUpdates];
            } else if (state == SVPullingStateTriggeredClose) {
                if ([weakSelf.delegate respondsToSelector:@selector(tagsTableViewControllerDidDimiss:)]) {
                    [weakSelf.delegate tagsTableViewControllerDidDimiss:weakSelf];
                }
            }
        });
    }];

    self.tableView.pullingView.addingHeight  = 60;
    self.tableView.pullingView.closingHeight = 90;
}

- (void)viewDidDisappear:(BOOL)animated {
    self.tags = nil;

    [self.tableView disablePulling];

    [self.tableView disableGestureTableViewWithRecognizer:self.tableViewRecognizer];
    self.tableViewRecognizer = nil;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.tagInEditState) {
        NSUInteger index       = [self.tags indexOfObject:self.tagInEditState];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];

        [self gestureRecognizer:self.tableViewRecognizer cancelEditingState:TransformableTableViewCellEditingStateRight forRowAtIndexPath:indexPath];
    }
}

#pragma mark -
#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.tags.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.transformingMovingIndexPath && self.transformingMovingIndexPath.row == indexPath.row) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"grabbedTableViewCellIdentifier"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    } else {
        NSUInteger index = (NSUInteger)indexPath.row;
        Tag *tag         = [self.tags objectAtIndex:index];

        TagTableViewCell *cell = (TagTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TagsTableViewCellIdentifier"];

        NSString *tagName = [tag.name copy];
        cell.nameTextField.text = tagName;
        cell.name.text          = tagName ? [tagName uppercaseString] : @"-- --";

        cell.delegate = self;

        [cell marked:[self.event.inTag isEqual:tag] ? YES:NO withAnimation:NO];

        return cell;
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    [cell marked:NO withAnimation:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Now we check if we have any cells in editstate,
    // if so we animate them back to normal state
    if (self.tagInEditState) {
        NSUInteger editStateIndex       = [self.tags indexOfObject:self.tagInEditState];
        NSIndexPath *editStateIndexPath = [NSIndexPath indexPathForRow:(NSInteger)editStateIndex inSection:0];

        TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:editStateIndexPath];
        CGPoint fromValue      = cell.frontView.layer.position;
        CGPoint toValue        = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];
    }

    TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    [cell marked:!cell.marked withAnimation:YES];

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    self.event.inTag = [self.event.inTag isEqual:tag] ? nil : tag;

    if ([self.delegate respondsToSelector:@selector(tagsTableViewControllerDidDimiss:)]) {
        [self.delegate tagsTableViewControllerDidDimiss:self];
    }
}

#pragma mark -
#pragma mark TagTableViewCellDelegate

- (void)cell:(TagTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    [[DataRepository instance] deleteTag:tag];

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];

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
    CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];

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

    UIImage *background = [UIImage imageNamed:@"stressed_linen"];
    cell.backView.backgroundColor = [UIColor colorWithPatternImage:background];

    UIImage *deleteButton = [UIImage imageNamed:@"delete"];
    [cell.deleteButton setImage:deleteButton forState:UIControlStateNormal];
    [cell.deleteButton setImage:deleteButton forState:UIControlStateHighlighted];
    [cell.deleteButton setImage:deleteButton forState:UIControlStateSelected];

    if (!cell.backViewInnerShadowLayer) {
        InnerShadowLayer *innerShadowLayer = [self innerShadowLayerForCell:cell];
        cell.backViewInnerShadowLayer = innerShadowLayer;
        [cell.backView.layer addSublayer:innerShadowLayer];
    }

    [self addFrontViewShadowToCell:cell];

    // If we have a cell in editstate and it is not this cell then cancel it
    if (self.tagInEditState && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        NSIndexPath *indexPathInEditState = [NSIndexPath indexPathForRow:(NSInteger)indexOfTagInEditState inSection:0];
        [self gestureRecognizer:gestureRecognizer cancelEditingState:state forRowAtIndexPath:indexPathInEditState];
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && indexOfTagInEditState != (NSUInteger)indexPath.row) {
        return;
    }

    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    NSInteger xOffset = indexOfTagInEditState == (NSUInteger)indexPath.row ? self.editingStateRightOffset : 0;

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
        CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds) + self.editingStateRightOffset, fromValue.y);

        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];

        self.tagInEditState = [self.tags objectAtIndex:indexPath.row];
    } else {
        CGPoint fromValue = cell.frontView.layer.position;
        CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

        // Dimiss if we are showing it
        [cell.nameTextField resignFirstResponder];
        [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];

        self.tagInEditState = nil;
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    CGPoint fromValue = cell.frontView.layer.position;
    CGPoint toValue   = CGPointMake(CGRectGetMidX(cell.frontView.layer.bounds), fromValue.y);

    self.tagInEditState = nil;

    [self animateBounceOnLayer:cell.frontView.layer fromPoint:fromValue toPoint:toValue withDuration:1.5f completion:nil];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger indexOfTagInEditState = [self.tags indexOfObject:self.tagInEditState];
    // if this indexPath is in a edit state then return 0 else return normal
    return indexPath.row == (NSInteger)indexOfTagInEditState ? 0 : self.editingCommitLength;
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
    innerShadowLayer.shadowMask = InnerShadowMaskTop | InnerShadowMaskBottom;
    innerShadowLayer.frame         = cell.backView.frame;
    innerShadowLayer.shadowRadius  = 3;
    innerShadowLayer.shadowOpacity = 0.8f;

    return innerShadowLayer;
}

- (void)addFrontViewShadowToCell:(TagTableViewCell *)cell {
    cell.frontView.layer.shadowColor   = [[UIColor colorWithWhite:0 alpha:1] CGColor];
    cell.frontView.layer.masksToBounds = NO;
    cell.frontView.layer.shadowOffset  = CGSizeMake(0.0f, 0.0f);
    cell.frontView.layer.shadowRadius  = 2;
    cell.frontView.layer.shadowOpacity = 0.7f;
    CGRect shadowFrame = CGRectInset(cell.frontView.bounds, 0.0f, 4);
    cell.frontView.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowFrame].CGPath;
}

- (void)animateBounceOnLayer:(CALayer *)layer fromPoint:(CGPoint)from toPoint:(CGPoint)to withDuration:(CFTimeInterval)duration completion:(void (^)(BOOL finished))completion {
    static NSString *keyPath = @"position";

    SKBounceAnimation *positionAnimation = [SKBounceAnimation animationWithKeyPath:keyPath];
    positionAnimation.fromValue       = [NSValue valueWithCGPoint:from];
    positionAnimation.toValue         = [NSValue valueWithCGPoint:to];
    positionAnimation.duration        = duration;
    positionAnimation.numberOfBounces = 4;
    positionAnimation.completion      = completion;

    [layer addAnimation:positionAnimation forKey:keyPath];
    [layer setValue:[NSValue valueWithCGPoint:to] forKeyPath:keyPath];
}

@end