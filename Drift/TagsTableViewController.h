//
//  TagsTableViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-07.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface TagsTableViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic) Event *event;

@end
