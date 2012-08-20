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
@property (nonatomic) NSTimer *updateTimer;

@end

@implementation EventGroupTableViewCell

#pragma mark -
#pragma mark Application lifecycle

//- (void)awakeFromNib {
//	self.runningTimeHours.font   = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:96];
//	self.runningTimeMinutes.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:40];
//	self.dateDay.font            = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:36];
//	self.dateYear.font           = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
//	self.dateMonth.font          = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
//}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		NSDateFormatter *dateFormatter = [NSDateFormatter new];
		self.monthNames = [dateFormatter standaloneMonthSymbols];
	}

	return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
	if (!newSuperview) {
		[self.updateTimer invalidate];
	}
}

#pragma mark -
#pragma mark Public instance methods

- (void)addEventGroup:(EventGroup *)eventGroup {
	[self.updateTimer invalidate];

	self.eventGroup = eventGroup;

	if (self.eventGroup.isRunning) {
		// Add timer to update the time
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:60
															target:self
														  selector:@selector(timerUpdate)
														  userInfo:nil
														   repeats:YES];
	}

	[self updateTime];
}

#pragma mark -
#pragma mark Private instance methods

- (void)timerUpdate {
	[self updateTime];
}

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
