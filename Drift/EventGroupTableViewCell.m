//
//  EventGroupTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupTableViewCell.h"

@interface EventGroupTableViewCell ()

@property (nonatomic, readwrite) EventGroup *eventGroup;
@property (nonatomic) NSArray *monthNames;

@end

@implementation EventGroupTableViewCell

#pragma mark -
#pragma mark Application lifecycle

- (void)awakeFromNib {
	self.runningTimeHours.font   = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:96];
	self.runningTimeMinutes.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:40];
	self.dateDay.font            = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:36];
	self.dateYear.font           = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
	self.dateMonth.font          = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.monthNames = [[NSDateFormatter new] standaloneMonthSymbols];
	}

	return self;
}

#pragma mark -
#pragma mark Public instance methods

- (void)addEventGroup:(EventGroup *)eventGroup {
	self.eventGroup = eventGroup;

	[self updateTime];
}

#pragma mark -
#pragma mark Private instance methods

- (void)updateTime {
	NSDateComponents *components = self.eventGroup.groupTime;

	// And finally update the running timer
	self.runningTimeHours.text   = [NSString stringWithFormat:@"%02d", components.hour];
	self.runningTimeMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];

	unsigned int unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.eventGroup.groupDate];

	self.dateDay.text   = [NSString stringWithFormat:@"%02d", components.day];
	self.dateYear.text  = [NSString stringWithFormat:@"%04d", components.year];
	self.dateMonth.text = [self.monthNames objectAtIndex:(components.month - 1)];
}

@end
