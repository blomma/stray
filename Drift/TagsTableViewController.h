//
//  TagsTableViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "Tag.h"

@class TagsTableViewController;

@interface TagsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, copy) void (^didDismissHandler)(void);
@property (nonatomic, copy) void (^didEditTagHandler)(Tag *tag);
@property (nonatomic, copy) void (^didDeleteTagHandler)(Tag *tag);
@property (nonatomic, copy) void (^didSelectTagHandler)(Tag *tag);
@property (nonatomic, copy) BOOL (^isTagSelectedHandler)(Tag *tag);

@end
