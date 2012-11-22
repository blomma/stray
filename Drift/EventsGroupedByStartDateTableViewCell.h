//
//  EventTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

#import "TagButton.h"

@protocol EventsGroupedByStartDateTableViewCellDelegate <NSObject>

- (void)cell:(UITableViewCell *)cell tappedTagButton:(UIButton *)sender forEvent:(UIEvent *)event;

@end

@interface EventsGroupedByStartDateTableViewCell : UITableViewCell

@property (nonatomic, weak) id<EventsGroupedByStartDateTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *eventStartTime;
@property (weak, nonatomic) IBOutlet UILabel *eventStartDay;
@property (weak, nonatomic) IBOutlet UILabel *eventStartMonth;
@property (weak, nonatomic) IBOutlet UILabel *eventStartYear;

@property (weak, nonatomic) IBOutlet UILabel *eventTimeHours;
@property (weak, nonatomic) IBOutlet UILabel *eventTimeMinutes;

@property (weak, nonatomic) IBOutlet UILabel *eventStopTime;
@property (weak, nonatomic) IBOutlet UILabel *eventStopDay;
@property (weak, nonatomic) IBOutlet UILabel *eventStopMonth;
@property (weak, nonatomic) IBOutlet UILabel *eventStopYear;

@property (weak, nonatomic) IBOutlet TagButton *tagName;

- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event;

@end
