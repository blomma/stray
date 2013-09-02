//
//  EventTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagButton.h"

@interface EventCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *hours;
@property (weak, nonatomic) IBOutlet UILabel *minutes;

@property (weak, nonatomic) IBOutlet UIView *timeContainer;
@property (weak, nonatomic) IBOutlet UILabel *startTime;
@property (weak, nonatomic) IBOutlet UILabel *startDate;
@property (weak, nonatomic) IBOutlet UILabel *stopTime;
@property (weak, nonatomic) IBOutlet UILabel *stopDate;

@property (weak, nonatomic) IBOutlet UIView *tagContainer;
@property (weak, nonatomic) IBOutlet TagButton *tagButton;

@property (nonatomic, copy) void (^didSelectTagHandler)(void);

@property (nonatomic) BOOL marked;

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation;
- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event;

@end
