//
//  EventTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

#import "TagButton.h"

@interface EventsGroupedByStartDateTableViewCell : UITableViewCell

@property (nonatomic, copy) void (^didDeleteEventHandler)(UITableViewCell *cell);
@property (nonatomic, copy) void (^didEditTagHandler)(UITableViewCell *cell);

@property (nonatomic, weak) IBOutlet UIView *backView;

@property (nonatomic, weak) IBOutlet UIView *frontView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *frontViewLeading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *frontViewTrailing;

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

@property (nonatomic, weak) IBOutlet UIButton *deleteButton;

@property (weak, nonatomic) IBOutlet UIView *rightSelected;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftSeparator;
@property (weak, nonatomic) IBOutlet TagButton *tagButton;

@property (nonatomic) BOOL marked;

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation;
- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event;

@end
