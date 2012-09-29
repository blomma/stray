	//
//  TagViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-22.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagViewController.h"
#import "TagCollectionViewCell.h"
#import "NSManagedObject+ActiveRecord.h"
#import "Tag.h"
#import "UIViewController+KNSemiModal.h"
#import "CreateTagViewController.h"

@interface TagViewController ()

@property (nonatomic) NSMutableArray *tags;
@property (nonatomic) CreateTagViewController *createTagPopup;

@property (nonatomic) BOOL editingTags;

@end

@implementation TagViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tags = [[NSMutableArray alloc] initWithArray:[Tag all]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:NSManagedObjectContextDidSaveNotification
	                                           object:[[CoreDataManager instance] managedObjectContext]];

    NSUInteger index = [self.tags indexOfObject:self.event.inTag];
    if (index == NSNotFound) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)index
                                           inSection:0];

    [self.collectionView selectItemAtIndexPath:path animated:YES scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:[[CoreDataManager instance] managedObjectContext]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    DLog(@"self.tags.count %u", self.tags.count);
    return (NSInteger)self.tags.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *tagCellIdentifier = @"TagCollectionViewCell";

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    TagCollectionViewCell *cell = (TagCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:tagCellIdentifier
                                                                                                     forIndexPath:indexPath];

    cell.tagName.text = tag.name;
    cell.deleteTag.hidden = !self.editingTags;

    if (self.editingTags) {
        cell.tagName.alpha = 0.5;
    } else {
        cell.tagName.alpha = 1;
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"TagCollectionViewHeader";

    UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:CellIdentifier forIndexPath:indexPath];

    return header;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    if (![self.event.inTag isEqual:tag]) {
        self.event.inTag = tag;
        [[CoreDataManager instance] saveContext];

        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark -
#pragma mark Private methods

- (IBAction)createTag:(id)sender {
    self.createTagPopup = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateTagPopup"];
    [self presentSemiViewController:self.createTagPopup];
}

- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)editTags:(id)sender {
    self.editingTags = !self.editingTags;

    // Invalidate all the cells so they refresh
    [self.collectionView reloadData];

    NSUInteger index = [self.tags indexOfObject:self.event.inTag];

    if (index != NSNotFound) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)index
                                               inSection:0];

        [self.collectionView selectItemAtIndexPath:path animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    }

}

- (IBAction)deleteCell:(id)sender forEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    [tag delete];
}

- (void)dataModelDidSave:(NSNotification *)note {
    // Inserted Tags
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
    NSArray *insertedTags = [[insertedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }] allObjects];

    DLog(@"insertedObjects %@", insertedObjects);
    DLog(@"insertedTags %@", insertedTags);

    [self.tags addObjectsFromArray:insertedTags];

    NSMutableArray *insertIndexPaths = [NSMutableArray array];

    for (Tag *tag in insertedTags) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)[self.tags indexOfObject:tag] inSection:0];
        [insertIndexPaths addObject:path];
    }

    DLog(@"insertIndexPaths %@", insertIndexPaths);

    // Deleted tags
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSArray *deletedTags = [[deletedObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[Tag class]];
    }] allObjects];

    DLog(@"deletedObjects %@", deletedObjects);
    DLog(@"deletedTags %@", deletedTags);

    NSMutableArray *deletedIndexPaths = [NSMutableArray array];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (Tag *tag in deletedTags) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)[self.tags indexOfObject:tag] inSection:0];
        [deletedIndexPaths addObject:path];
        
        [indexesToRemove addIndex:(NSUInteger)path.row];
    }

    DLog(@"deletedIndexPaths %@", deletedIndexPaths);
    DLog(@"indexesToRemove %@", indexesToRemove);

    [self.tags removeObjectsAtIndexes:indexesToRemove];

    // If this was the last and we are in edit mode then exit it
    if (self.tags.count == 0) {
        self.editingTags = !self.editingTags;
    }

    [self.collectionView performBatchUpdates:^{
        if (insertIndexPaths.count > 0) {
            DLog(@"insertIndexPaths %@", insertIndexPaths);
            [self.collectionView insertItemsAtIndexPaths:insertIndexPaths];
        }

        if (deletedIndexPaths.count > 0) {
            DLog(@"deletedIndexPaths %@", deletedIndexPaths);
            [self.collectionView deleteItemsAtIndexPaths:deletedIndexPaths];
        }
    } completion:nil];
}

@end
