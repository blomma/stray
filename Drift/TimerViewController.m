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

@property (nonatomic) Event *currentEvent;

@end

@implementation TimerViewController

#pragma mark -
#pragma mark private properties

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
		
		[self.timerFaceControl startWithDate:self.currentEvent.startDate];
	}
	else {
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}
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
	
	// Start observing
	[self.timerFaceControl addObserver:self 
							forKeyPath:@"startDate" 
							   options:NSKeyValueObservingOptionNew 
							   context:NULL];

	[self.timerFaceControl addObserver:self 
							forKeyPath:@"nowDate" 
							   options:NSKeyValueObservingOptionNew 
							   context:NULL];

	[self.timerFaceControl addObserver:self 
							forKeyPath:@"stopDate" 
							   options:NSKeyValueObservingOptionNew 
							   context:NULL];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Public instance methods

- (IBAction)toggleTimer:(id)sender {
	NSDate *now = [NSDate date];

	// Do we have a event that is running
	if (![self.currentEvent runningValue]) {
		[TestFlight passCheckpoint:@"START TIMER"];

		// No, lets create a new one
		Event *event = [Event MR_createEntity];
		event.runningValue = TRUE;

		// Stow it away for easy access
		self.currentEvent = event;

		// Finally start up the face
		[self.timerFaceControl startWithDate:now];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	}
	else {
		[TestFlight passCheckpoint:@"STOP TIMER"];

		self.currentEvent.runningValue = FALSE;

		[self.timerFaceControl stopWithDate:now];

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}

	[[NSManagedObjectContext MR_defaultContext] MR_save];
}

#pragma mark -
#pragma mark Private Instance methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *startDate = [change objectForKey:NSKeyValueChangeNewKey];

		// Update the event
		self.currentEvent.startDate = startDate;

		// Update start time
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
		self.startDateLabel.text = [formatter stringFromDate:startDate];
	} else if ([keyPath isEqualToString:@"nowDate"]) {
		NSDate *nowDate = [change objectForKey:NSKeyValueChangeNewKey];

		// Get conversion to months, days, hours, minutes
		unsigned int unitFlags       = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
		NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.currentEvent.startDate toDate:nowDate options:0];
			
		// And finally update the running timer
		self.runningTimerHourLabel.text   = [NSString stringWithFormat:@"%02d", components.hour];
		self.runningTimerMinuteLabel.text = [NSString stringWithFormat:@"%02d", components.minute];
		self.runningTimerSecondLabel.text = [NSString stringWithFormat:@"%02d", components.second];
	} else if ([keyPath isEqualToString:@"stopDate"]) {
		NSDate *stopDate = [change objectForKey:NSKeyValueChangeNewKey];

		// Update the event
		self.currentEvent.stopDate = stopDate;

		// Get conversion to months, days, hours, minutes
		unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
		
		NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.currentEvent.startDate toDate:stopDate options:0];
		
	}

	//[[NSManagedObjectContext MR_defaultContext] MR_save];
}

@end