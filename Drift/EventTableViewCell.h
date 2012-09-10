//
//  EventTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface EventTableViewCell : UITableViewCell

@property (nonatomic) Event *event;

@property (nonatomic, weak) IBOutlet UILabel *eventStart;
@property (nonatomic, weak) IBOutlet UILabel *eventStop;
@property (nonatomic, weak) IBOutlet UILabel *eventTime;

@end
