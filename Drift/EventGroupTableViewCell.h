//
//  EventGroupTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"

@interface EventGroupTableViewCell : UITableViewCell

@property (nonatomic) IBOutlet UILabel *runningTimeHours;
@property (nonatomic) IBOutlet UILabel *runningTimeMinutes;
@property (nonatomic) IBOutlet UILabel *dateDay;
@property (nonatomic) IBOutlet UILabel *dateMonth;
@property (nonatomic) IBOutlet UILabel *dateYear;

@property (nonatomic, readonly) EventGroup *eventGroup;

- (void)addEventGroup:(EventGroup *)eventGroup;
- (void)updateTime;

@end
