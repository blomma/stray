//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventDataManager.h"
#import "EventViewController.h"

@interface EventViewController ()

@property (nonatomic) NSDateFormatter *startDateFormatter;
@property (nonatomic) NSCalendar *calender;

@end

@implementation EventViewController

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
        // Startdate formatter
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        self.startDateFormatter = formatter;

        self.calender = [NSCalendar currentCalendar];
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

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"startDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"nowDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];
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
	self.startDateLabel.text = [self.startDateFormatter stringFromDate:date];
}

- (void)updateNowLabel:(NSDate *)date {
	Event *event = [[EventDataManager sharedManager] currentEvent];

	unsigned int static unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
	NSDateComponents *components = [self.calender components:unitFlags fromDate:event.startDate toDate:date options:0];

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