//
//  EventGroupTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupTableViewCell.h"

@implementation EventGroupTableViewCell

- (void)awakeFromNib {
	self.runningTimeHours.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:96];
	self.runningTimeMinutes.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:40];
	self.dateDay.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:36];
	self.dateYear.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
	self.dateMonth.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
	}

	return self;
}

@end
