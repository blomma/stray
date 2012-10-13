//
//  UITableView+Change.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "UITableView+Change.h"
#import "Change.h"

@implementation UITableView (Change)

- (void)updateWithChanges:(NSSet *)changes {
    if (changes.count > 0) {
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

        [self beginUpdates];

        DLog(@"insertIndexPaths %@", insertIndexPaths);
        [self insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationRight];

        DLog(@"deleteIndexPaths %@", deleteIndexPaths);
        [self deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];

        DLog(@"updateIndexPaths %@", updateIndexPaths);
        [self reloadRowsAtIndexPaths:updateIndexPaths withRowAnimation:UITableViewRowAnimationNone];

        [self endUpdates];
    }
}

@end