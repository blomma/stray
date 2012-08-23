//
//  EventGroupTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"

typedef enum {
    EventGroupTableViewCellPositionTop = 0,
    EventGroupTableViewCellPositionMiddle,
    EventGroupTableViewCellPositionBottom,
    EventGroupTableViewCellPositionAlone
} EventGroupTableViewCellPosition;

@interface EventGroupTableViewCell : UITableViewCell

@property (nonatomic) IBOutlet UILabel *hours;
@property (nonatomic) IBOutlet UILabel *minutes;
@property (nonatomic) IBOutlet UILabel *day;
@property (nonatomic) IBOutlet UILabel *weekDay;
@property (nonatomic) IBOutlet UILabel *month;
@property (nonatomic) IBOutlet UILabel *year;

@property (nonatomic, readonly) EventGroup *eventGroup;
@property (nonatomic) EventGroupTableViewCellPosition position;

+ (NSArray *)monthNames;
+ (NSArray *)weekNames;

- (void)addEventGroup:(EventGroup *)eventGroup;
- (void)updateTime;

@end
