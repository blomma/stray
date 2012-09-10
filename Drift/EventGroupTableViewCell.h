//
//  EventGroupTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"

@interface EventGroupTableViewCell : UITableViewCell

@property (nonatomic) EventGroup *eventGroup;

@property (nonatomic, weak) IBOutlet UILabel *hours;
@property (nonatomic, weak) IBOutlet UILabel *minutes;
@property (nonatomic, weak) IBOutlet UILabel *day;
@property (nonatomic, weak) IBOutlet UILabel *weekDay;
@property (nonatomic, weak) IBOutlet UILabel *month;
@property (nonatomic, weak) IBOutlet UILabel *year;

@end
