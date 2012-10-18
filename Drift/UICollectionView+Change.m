//
//  UICollectionView+Update.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "UICollectionView+Change.h"
#import "Change.h"

@implementation UICollectionView (Change)

- (void)updateWithChanges:(NSArray *)changes {
    if (changes.count == 0) {
        return;
    }

    NSMutableArray *insertIndexPaths = [NSMutableArray array];
    NSMutableArray *deleteIndexPaths = [NSMutableArray array];
    NSMutableArray *updateIndexPaths = [NSMutableArray array];

    for (Change *change in changes) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)change.index inSection:0];
        if ([change.type isEqualToString:ChangeUpdate]) {
            [updateIndexPaths addObject:path];
        } else if ([change.type isEqualToString:ChangeDelete]) {
            [deleteIndexPaths addObject:path];
        } else if ([change.type isEqualToString:ChangeInsert]) {
            [insertIndexPaths addObject:path];
        }
    }

    [self performBatchUpdates:^{
        [self insertItemsAtIndexPaths:insertIndexPaths];
        [self deleteItemsAtIndexPaths:deleteIndexPaths];
        [self reloadItemsAtIndexPaths:deleteIndexPaths];
    } completion:nil];
}

@end