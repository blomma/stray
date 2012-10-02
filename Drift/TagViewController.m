//
//  TagViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-22.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagViewController.h"
#import "TagCollectionViewCell.h"
#import "Tag.h"
#import "UIViewController+KNSemiModal.h"
#import "CreateTagViewController.h"
#import "UICollectionView+Change.h"
#import "DataManager.h"
#import "NSManagedObject+ActiveRecord.h"

@interface TagViewController ()

@property (nonatomic) CreateTagViewController *createTagPopup;

@property (nonatomic) BOOL editingTags;

@end

@implementation TagViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:kDataManagerDidSaveNotification
	                                           object:[DataManager instance]];

    NSUInteger index = [[[DataManager instance] tags] indexOfTag:self.event.inTag];
    if (index != NSNotFound) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)index
                                               inSection:0];
        [self.collectionView selectItemAtIndexPath:path animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kDataManagerDidSaveNotification
                                                  object:[DataManager instance]];
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
    DLog(@"self.tags.count %u", [[DataManager instance] tags].count);
    return (NSInteger)[[DataManager instance] tags].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *tagCellIdentifier = @"TagCollectionViewCell";

    Tag *tag = [[[DataManager instance] tags] tagAtIndex:(NSUInteger)indexPath.row];
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
    Tag *tag = [[[DataManager instance] tags] tagAtIndex:(NSUInteger)indexPath.row];

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

    NSUInteger index = [[[DataManager instance] tags] indexOfTag:self.event.inTag];

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

    Tag *tag = [[[DataManager instance] tags] tagAtIndex:(NSUInteger)indexPath.row];
    [tag delete];
}

- (void)dataModelDidSave:(NSNotification *)note {
    // If this was the last and we are in edit mode then exit it
    if ([[DataManager instance] tags].count == 0) {
        self.editingTags = NO;
    }

	NSSet *tagChangeObjects = [[note userInfo] objectForKey:kTagChangesKey];

    // Fix, for some reason we get these on off errors doing a batchUpdate for the first insert
    // or last delete, we loose selection in this instance, but that doesnt matter.
    if ([[DataManager instance] tags].count <= 1) {
        [self.collectionView reloadData];
    } else {
        [self.collectionView updateWithChanges:[tagChangeObjects allObjects]];
    }
}

@end
