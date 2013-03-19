//
//  TagsTableViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

@class TagsTableViewController;

@protocol TagsTableViewControllerDelegate <NSObject>

- (void)tagsTableViewControllerDidDimiss;

@end

@interface TagsTableViewController : UITableViewController

@property (nonatomic, weak) id<TagsTableViewControllerDelegate> delegate;
@property (nonatomic, weak) Event *event;

@end
