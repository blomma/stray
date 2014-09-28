//
//  TagsTableViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagsTableViewController.h"

#import "Tag.h"
#import "TransformableTableViewGestureRecognizer.h"
#import "TagTableViewCell.h"
#import "UIScrollView+AIPulling.h"
#import "State.h"
#import "Stray-Swift.h"

@interface TagsTableViewController ()<TransformableTableViewGestureEditingRowDelegate, TagTableViewCellDelegate, ReorderTableViewControllerDelegate>

@property (nonatomic) TransformableTableViewGestureRecognizer *tableViewRecognizer;
@property (nonatomic, strong) ReorderTableViewController *reorderTableViewController;

@property (nonatomic) Tag *tagInEditState;

@property (nonatomic) NSIndexPath *reorderIndexPath;
@property (nonatomic) NSInteger editingCommitLength;

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation TagsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.editingCommitLength = 60;

    self.tableViewRecognizer = [self.tableView enableGestureTableViewWithDelegate:self];

    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"reorderTableViewCellIdentifier"];

    self.reorderTableViewController = [[ReorderTableViewController alloc] initWithTableView:self.tableView];
    self.reorderTableViewController.delegate = self;
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullingWithActionHandler:^(AIPullingState state, AIPullingState previousState, CGFloat height) {
        if (state == AIPullingStateAction && previousState == AIPullingStatePullingAdd) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [Tag MR_createEntity];
            });
        } else if (state == AIPullingStateAction && previousState == AIPullingStatePullingClose) {
            if ([weakSelf.delegate respondsToSelector:@selector(tagsTableViewControllerDidDimiss)]) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    [weakSelf.delegate tagsTableViewControllerDidDimiss];
                });
            }
        }
    }];

    self.tableView.pullingView.addingHeight  = 60;
    self.tableView.pullingView.closingHeight = 90;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    Event *event = [Event MR_findFirstByAttribute:@"guid"
                                        withValue:self.eventGUID];
    
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:event.inTag];
    
    [self.tableView selectRowAtIndexPath:indexPath
                                animated:NO
                          scrollPosition:UITableViewScrollPositionNone];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.tableView disablePulling];
    [self.tableView disableGestureTableViewWithRecognizer:self.tableViewRecognizer];
}

#pragma mark -
#pragma mark Private properties

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController == nil) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Tag"];
        [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"sortIndex"
                                                                       ascending:YES]]];
        [fetchRequest setFetchBatchSize:20];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[NSManagedObjectContext MR_defaultContext]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        
        _fetchedResultsController.delegate = self;
        
        NSError *error;
        if (![_fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            exit(-1);
        }
    }
    
    return _fetchedResultsController;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.tagInEditState) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];
        
        [self gestureRecognizer:self.tableViewRecognizer
             cancelEditingState:TransformableTableViewCellEditingStateRight
              forRowAtIndexPath:indexPath];
    }
}

#pragma mark -
#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[[[self.fetchedResultsController sections] objectAtIndex:(NSUInteger)section] numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[[self.fetchedResultsController sections] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.reorderIndexPath && [self.reorderIndexPath isEqual:indexPath] ) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reorderTableViewCellIdentifier"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    } else {
        TagTableViewCell *cell = (TagTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TagsTableViewCellIdentifier"];
        [self configureCell:cell atIndexPath:indexPath];
        
        return cell;
    }
}

- (void)configureCell:(TagTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.tagTitle = tag.name;
    cell.delegate = self;
    Event *event = [Event MR_findFirstByAttribute:@"guid"
                                        withValue:self.eventGUID];
    
    BOOL selected = [event.inTag isEqual:tag] ? YES : NO;
    [cell marked:selected withAnimation:NO];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // If this is a tag with no name then we cant select it
    if (!tag.name) {
        return;
    }

    TagTableViewCell *cell = (TagTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    [cell marked:!cell.marked withAnimation:YES];

    Event *event = [Event MR_findFirstByAttribute:@"guid"
                                        withValue:self.eventGUID];
    
    event.inTag = [event.inTag isEqual:tag] ? nil : tag;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
    
    [self.delegate tagsTableViewControllerDidDimiss];
}

#pragma mark -
#pragma mark TagTableViewCellDelegate

- (void)cell:(TagTableViewCell *)cell tappedDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    [cell.tagNameTextField resignFirstResponder];

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];

    [tag MR_deleteEntity];

    self.tagInEditState = nil;

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
}

- (void)cell:(TagTableViewCell *)cell didChangeTagName:(NSString *)name {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

    if (name && ![name isEqualToString:@""]) {
        Tag *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
        tag.name = name;
        cell.tagTitle = name;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
    }

    [UIView animateWithDuration:1
                          delay:0
         usingSpringWithDamping:0.6f
          initialSpringVelocity:0
                        options:0
                     animations:^{
                         cell.leading.constant = 0;
                         [cell.frontView layoutIfNeeded];
                     }
                     completion:nil];

    self.tagInEditState = nil;
}

#pragma mark -
#pragma mark TransformableTableViewGestureEditingRowDelegate

- (BOOL)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didEnterEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];

    if (state == TransformableTableViewCellEditingStateLeft && ![editStateIndexPath isEqual:indexPath]) {
        return;
    }

    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.frontView.layer removeAllAnimations];

    // If we have a cell in editstate and it is not this cell then cancel it
    if (self.tagInEditState && ![editStateIndexPath isEqual:indexPath]) {
        [self gestureRecognizer:gestureRecognizer
             cancelEditingState:state
              forRowAtIndexPath:editStateIndexPath];
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer didChangeEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && ![editStateIndexPath isEqual:indexPath]) {
        return;
    }

    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    CGFloat rightConstant = cell.frame.size.width - cell.backViewToEdit.constant - cell.leftSeparator.constant;
    CGFloat xOffset = [editStateIndexPath isEqual:indexPath] ? rightConstant : 0;

    cell.leading.constant = gestureRecognizer.translationInTableView.x + xOffset;

    [cell.frontView layoutIfNeeded];
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer commitEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];
    if (state == TransformableTableViewCellEditingStateLeft && ![editStateIndexPath isEqual:indexPath]) {
        return;
    }

    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];

    if (state == TransformableTableViewCellEditingStateRight && !self.tagInEditState) {
        CGFloat rightConstant = cell.frame.size.width - cell.backViewToEdit.constant - cell.leftSeparator.constant;
        CGFloat velocity = ABS(gestureRecognizer.velocity.x) / (rightConstant - cell.leading.constant);

        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.6f
              initialSpringVelocity:velocity
                            options:0
                         animations:^{
                             cell.leading.constant = rightConstant;
                             [cell.frontView layoutIfNeeded];
                         }
                         completion:nil];

        self.tagInEditState = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else {
        CGFloat velocity = ABS(gestureRecognizer.velocity.x) / cell.leading.constant;

        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.6f
              initialSpringVelocity:velocity
                            options:0
                         animations:^{
                             cell.leading.constant = 0;
                             [cell.frontView layoutIfNeeded];
                         }
                         completion:nil];

        self.tagInEditState = nil;
    }
}

- (void)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer cancelEditingState:(TransformableTableViewCellEditingState)state forRowAtIndexPath:(NSIndexPath *)indexPath {
    TagTableViewCell *cell = (TagTableViewCell *)[gestureRecognizer.tableView cellForRowAtIndexPath:indexPath];
    [cell.tagNameTextField resignFirstResponder];

    CGFloat velocity = ABS(gestureRecognizer.velocity.x) / cell.leading.constant;

    [UIView animateWithDuration:1
                          delay:0
         usingSpringWithDamping:0.5
          initialSpringVelocity:velocity
                        options:0
                     animations:^{
                         cell.leading.constant = 0;
                         [cell.frontView layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         self.tagInEditState = nil;
                     }];
}

- (CGFloat)gestureRecognizer:(TransformableTableViewGestureRecognizer *)gestureRecognizer lengthForCommitEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *editStateIndexPath = [self.fetchedResultsController indexPathForObject:self.tagInEditState];
    
    // if this indexPath is in a edit state then return 0 else return normal
    return [editStateIndexPath isEqual:indexPath] ? 0 : self.editingCommitLength;
}

#pragma mark -
#pragma mark ReorderTableViewControllerDelegate

- (BOOL)canMoveCellAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)willBeginMovingCellAtIndexPath:(NSIndexPath *)indexPath {
    self.reorderIndexPath = indexPath;
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)movedCellFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    self.reorderIndexPath = toIndexPath;
    
    Tag *atTag = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
    Tag *toTag = [self.fetchedResultsController objectAtIndexPath:toIndexPath];
    
    atTag.sortIndex = [NSNumber numberWithInteger:toIndexPath.row];
    toTag.sortIndex = [NSNumber numberWithInteger:fromIndexPath.row];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];

    [self.tableView beginUpdates];
    [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    [self.tableView endUpdates];
}

- (void)didMoveCellToIndexPath:(NSIndexPath *)toIndexPath {
    self.reorderIndexPath = nil;
    
    [self.tableView reloadRowsAtIndexPaths:@[toIndexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    if (self.reorderIndexPath) {
        return;
    }
    
    UITableView *tableView = self.tableView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(TagTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

@end
