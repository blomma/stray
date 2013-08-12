//
//  EventTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagButton.h"

@interface EventCell : UITableViewCell

@property (nonatomic, copy) void (^tagPressHandler)();

@property (nonatomic, weak) IBOutlet UIView *backView;
@property (nonatomic, weak) IBOutlet UIView *frontView;

@property (nonatomic, weak) IBOutlet UILabel *eventStartTime;
@property (nonatomic, weak) IBOutlet UILabel *eventStartDay;
@property (nonatomic, weak) IBOutlet UILabel *eventStartMonth;
@property (nonatomic, weak) IBOutlet UILabel *eventStartYear;

@property (nonatomic, weak) IBOutlet UILabel *eventTimeHours;
@property (nonatomic, weak) IBOutlet UILabel *eventTimeMinutes;

@property (nonatomic, weak) IBOutlet UILabel *eventStopTime;
@property (nonatomic, weak) IBOutlet UILabel *eventStopDay;
@property (nonatomic, weak) IBOutlet UILabel *eventStopMonth;
@property (nonatomic, weak) IBOutlet UILabel *eventStopYear;

@property (nonatomic, weak) IBOutlet TagButton *tagName;
@property (nonatomic, weak) IBOutlet UILabel *willDelete;

@property (nonatomic) BOOL marked;

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation;

- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event;

@end
