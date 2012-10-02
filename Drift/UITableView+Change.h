//
//  UITableView+Change.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-29.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (Change)

- (void)updateWithChanges:(NSArray *)changes;

@end