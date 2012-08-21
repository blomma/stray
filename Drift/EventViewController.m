//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventViewController.h"

#import "Event.h"
#import "EventDataManager.h"

@implementation EventViewController

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
	}

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	Event *currentEvent = [[EventDataManager sharedManager] currentEvent];

	if (currentEvent) {
		[self updateStartLabel:currentEvent.startDate];

		if (currentEvent.isActiveValue) {
			[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
			[self.eventTimerControl startWithDate:currentEvent.startDate];
		} else {
			[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];

			self.eventTimerControl.startDate = currentEvent.startDate;
			self.eventTimerControl.nowDate   = currentEvent.stopDate;
			self.eventTimerControl.stopDate  = currentEvent.stopDate;

			[self updateNowLabel:currentEvent.stopDate];
		}
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.startDateLabel.font                   = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:18];
	self.runningTimeLabel.font                 = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:55];
	self.toggleStartStopButton.titleLabel.font = [UIFont fontWithName:@"AlternateGothicNo2BT-Regular" size:50];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"startDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"nowDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Public instance methods

- (IBAction)toggleEvent:(id)sender {
	Event *currentEvent = [[EventDataManager sharedManager] currentEvent];

	NSDate *now         = [NSDate date];

	// Do we have a event that is running
	if (currentEvent.isActiveValue) {
		[TestFlight passCheckpoint:@"STOP EVENT"];

		currentEvent.isActiveValue = NO;
		currentEvent.stopDate     = now;

		// Stop the face
		[self.eventTimerControl stopWithDate:now];

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	} else {
		[TestFlight passCheckpoint:@"START EVENT"];

		// No, lets create a new one
		[[EventDataManager sharedManager] createEvent];
		currentEvent               = [[EventDataManager sharedManager] currentEvent];
		currentEvent.isActiveValue = YES;
		currentEvent.startDate     = now;

		// Start up the face
		[self.eventTimerControl startWithDate:now];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	}

	[[EventDataManager sharedManager] persistCurrentEvent];
}

#pragma mark -
#pragma mark Private Instance methods

- (void)updateStartLabel:(NSDate *)date {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	self.startDateLabel.text = [formatter stringFromDate:date];
}

- (void)updateNowLabel:(NSDate *)date {
	Event *currentEvent          = [[EventDataManager sharedManager] currentEvent];

	unsigned int unitFlags       = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:currentEvent.startDate toDate:date options:0];

	// And finally update the running timer
	self.runningTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", components.hour, components.minute, components.second];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

		[self updateStartLabel:date];
	} else if ([keyPath isEqualToString:@"nowDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

		[self updateNowLabel:date];
	}
}

@end