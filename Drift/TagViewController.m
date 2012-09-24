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

NSString *const TagDidChangeNotification = @"TagDidChangeNotification";

@interface TagViewController ()

@property (nonatomic) NSArray *tags;
@property (nonatomic) CreateTagViewController *createTagPopup;

@end

@implementation TagViewController

#pragma mark -
#pragma mark Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tags = [Tag all];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSUInteger index = [self.tags indexOfObject:self.event.inTag];

    if (index == NSNotFound) {
        return;
    }

    NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)index
                                           inSection:0];

    [self.collectionView selectItemAtIndexPath:path animated:YES scrollPosition:UICollectionViewScrollPositionNone];
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
    return (NSInteger)self.tags.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *tagCellIdentifier = @"TagCollectionViewCell";

    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];
    TagCollectionViewCell *cell = (TagCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:tagCellIdentifier
                                                                                                     forIndexPath:indexPath];
    cell.tagName.text = tag.name;

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"TagCollectionViewHeader";

    UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:CellIdentifier forIndexPath:indexPath];

    return header;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Tag *tag = [self.tags objectAtIndex:(NSUInteger)indexPath.row];

    [[NSNotificationCenter defaultCenter] postNotificationName:TagDidChangeNotification
                                                        object:self
                                                      userInfo:@{@"tag" : tag}];


    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

- (IBAction)createTag:(id)sender {
    self.createTagPopup = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateTagPopup"];
    [self presentSemiViewController:self.createTagPopup];
}

- (IBAction)dismissView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
