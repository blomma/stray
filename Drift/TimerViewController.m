//
//  TimerViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerViewController.h"
#import "Event.h"

@interface TimerViewController ()

@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) Event *currentEvent;

- (void)timerUpdate;

@end

@implementation TimerViewController

#pragma mark -
#pragma mark private properties

@synthesize updateTimer  = _updateTimer;
@synthesize currentEvent = _currentEvent;

#pragma mark -
#pragma mark public properties

@synthesize timerFaceControl                     = _timerFaceControl;
@synthesize toggleStartStopButton                = _toggleStartStopButton;
@synthesize startDateLabel                       = _startDateLabel;

@synthesize runningTimerHourLabel                = _runningTimerHourLabel;
@synthesize runningTimerMinuteLabel              = _runningTimerMinuteLabel;
@synthesize runningTimerSecondLabel              = _runningTimerSecondLabel;
@synthesize runningTimerHourMinuteDividerLabel   = _runningTimerHourMinuteDividerLabel;
@synthesize runningTimerMinuteSecondDividerLabel = _runningTimerMinuteSecondDividerLabel;

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
	}

	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	if ([self.currentEvent runningValue]) {
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
		self.startDateLabel.text = [formatter stringFromDate:self.currentEvent.startDate];

		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];

		// Set the starttime of the face
		self.timerFaceControl.startDate = self.currentEvent.startDate;

		if (![self.updateTimer isValid]) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
			                                                    target:self
			                                                  selector:@selector(timerUpdate)
			                                                  userInfo:nil
			                                                   repeats:YES];
		}

		[self.updateTimer fire];
	}
	else {
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[self.updateTimer invalidate];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Do we have a running event
	NSArray *eventArray = [Event MR_findByAttribute:@"running" withValue:[NSNumber numberWithBool:TRUE]];
	if ([eventArray count] == 1) {
		self.currentEvent = [eventArray objectAtIndex:0];
	}

	self.startDateLabel.font                       = [UIFont fontWithName:@"LeagueGothic" size:18];

	self.runningTimerHourMinuteDividerLabel.font   = [UIFont fontWithName:@"LeagueGothic" size:54];
	self.runningTimerMinuteSecondDividerLabel.font = [UIFont fontWithName:@"LeagueGothic" size:54];

	self.runningTimerHourLabel.font                = [UIFont fontWithName:@"LeagueGothic" size:55];
	self.runningTimerMinuteLabel.font              = [UIFont fontWithName:@"LeagueGothic" size:55];
	self.runningTimerSecondLabel.font              = [UIFont fontWithName:@"LeagueGothic" size:55];

	self.toggleStartStopButton.titleLabel.font     = [UIFont fontWithName:@"LeagueGothic" size:50];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Public instance methods

- (IBAction)toggleTimer:(id)sender {
	// Do we have a event that is running
	if (![self.currentEvent runningValue]) {
		[TestFlight passCheckpoint:@"START TIMER"];

		// No, lets create a new one
		Event *event = [Event MR_createEntity];
		event.startDate    = [NSDate date];
		event.runningValue = TRUE;

		// Stow it away for easy access
		self.currentEvent = event;

		// Update start time
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
		self.startDateLabel.text = [formatter stringFromDate:self.currentEvent.startDate];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];

		// Set the starttime of the face
		self.timerFaceControl.startDate = event.startDate;

		if (![self.updateTimer isValid]) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
			                                                    target:self
			                                                  selector:@selector(timerUpdate)
			                                                  userInfo:nil
			                                                   repeats:YES];
		}

		[self.updateTimer fire];
	}
	else {
		[TestFlight passCheckpoint:@"STOP TIMER"];

		NSDate *now = [NSDate date];

		[self.updateTimer invalidate];

		self.currentEvent.runningValue = FALSE;
		self.currentEvent.stopDate     = now;

		// Get conversion to months, days, hours, minutes
		unsigned int unitFlags       = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

		NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.currentEvent.startDate toDate:now options:0];

		self.currentEvent.runningTimeHours   = [NSNumber numberWithInt:components.hour];
		self.currentEvent.runningTimeMinutes = [NSNumber numberWithInt:components.minute];
		self.currentEvent.runningTimeSeconds = [NSNumber numberWithInt:components.second];

		self.timerFaceControl.stopDate       = now;

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}

	[[NSManagedObjectContext MR_defaultContext] MR_save];
}

#pragma mark -
#pragma mark Private Instance methods

- (void)timerUpdate {
	if ([self.currentEvent runningValue]) {
		NSDate *now = [NSDate date];

		// Update the timer face
		self.timerFaceControl.nowDate = now;

		// Get conversion to months, days, hours, minutes
		unsigned int unitFlags       = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
		NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.currentEvent.startDate toDate:now options:0];

		// And finally update the running timer
		self.runningTimerHourLabel.text   = [NSString stringWithFormat:@"%02d", components.hour];
		self.runningTimerMinuteLabel.text = [NSString stringWithFormat:@"%02d", components.minute];
		self.runningTimerSecondLabel.text = [NSString stringWithFormat:@"%02d", components.second];
	}
}

@end
