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

@property(nonatomic) NSTimer *updateTimer;
@property(nonatomic) Event *currentEvent;

- (void)timerUpdate;

@end

@implementation TimerViewController

#pragma mark -
#pragma mark private properties

@synthesize updateTimer = _updateTimer;
@synthesize currentEvent = _currentEvent;

#pragma mark -
#pragma mark public properties

@synthesize timerView = _timerView;
@synthesize toggleStartStopButton = _toggleStartStopButton;
@synthesize startDateLabel = _startDateLabel;
@synthesize runningTimeLabel = _runningTimeLabel;

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	DLog(@"%@", [UIFont fontNamesForFamilyName:@"Segoe UI"]);
	DLog(@"%@", [UIFont fontNamesForFamilyName:@"League Gothic"]);
	DLog(@"%@", [UIFont fontNamesForFamilyName:@"Josefin Sans Std"]);
	DLog(@"%@", [UIFont fontNamesForFamilyName:@"ChunkFive"]);

	if ([self.currentEvent runningValue])
	{
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"yyyy-MM-dd HH:mm"];
		self.startDateLabel.text = [formatter stringFromDate:self.currentEvent.startDate];

		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];

		if (![self.updateTimer isValid]) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
																target:self
															  selector:@selector(timerUpdate)
															  userInfo:nil
															   repeats:YES];
		}

		[self.updateTimer fire];
	} else {
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.updateTimer invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do we have a running event
	NSArray *eventArray = [Event MR_findByAttribute:@"running" withValue:[NSNumber numberWithBool:TRUE]];
	if ([eventArray count] == 1) {
		self.currentEvent = [eventArray objectAtIndex:0];
	}

//	self.startDateLabel.font = [UIFont fontWithName:@"SegoeUI-SemiBold" size:18];
//	self.runningTimeLabel.font = [UIFont fontWithName:@"SegoeUI-Light" size:55];
//	self.toggleStartStopButton.titleLabel.font = [UIFont fontWithName:@"SegoeUI-Light" size:50];

	self.startDateLabel.font = [UIFont fontWithName:@"LeagueGothic" size:18];
	self.runningTimeLabel.font = [UIFont fontWithName:@"LeagueGothic" size:55];
	self.toggleStartStopButton.titleLabel.font = [UIFont fontWithName:@"LeagueGothic" size:50];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(handleDataModelChange:)
//												 name:NSManagedObjectContextObjectsDidChangeNotification
//											   object:[NSManagedObjectContext MR_defaultContext]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Public instance methods

- (IBAction)toggleTimer:(id)sender
{
	// Do we have a event that is running
	if (![self.currentEvent runningValue]) {
		[TestFlight passCheckpoint:@"START TIMER"];
		
		// No, lets create a new one
		Event *event = [Event MR_createEntity];
		event.startDate = [NSDate date];
		event.runningValue = TRUE;

		// Stow it away for easy access
		self.currentEvent = event;

		// Update start time
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"yyyy-MM-dd HH:mm"];
		self.startDateLabel.text = [formatter stringFromDate:self.currentEvent.startDate];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];

		if (![self.updateTimer isValid]) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
																target:self
															  selector:@selector(timerUpdate)
															  userInfo:nil
															   repeats:YES];
		}

		[self.updateTimer fire];
	} else {
		[TestFlight passCheckpoint:@"STOP TIMER"];

		[self.updateTimer invalidate];

		self.currentEvent.runningValue = FALSE;
		self.currentEvent.stopDate = [NSDate date];

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}

	[[NSManagedObjectContext MR_defaultContext] MR_save];
}

#pragma mark -
#pragma mark Private Instance methods

- (void)timerUpdate
{
	if ([self.currentEvent runningValue]) {
		NSDate *now = [NSDate date];

		// The time interval
		NSTimeInterval timeInterval = [now timeIntervalSinceDate:self.currentEvent.startDate];

		// Get conversion to months, days, hours, minutes
		unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

		NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:self.currentEvent.startDate toDate:now  options:0];

		// Update the timer face
		[self.timerView updateForElapsedSecondsIntoHour:fmod(timeInterval, 3600)];

		// And finally update the running timer
		self.runningTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", components.hour, components.minute, components.second];
	}
}

//- (void)handleDataModelChange:(NSNotification *)note;
//{
//    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
//    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
//    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
//
//	// If we got a new Event then start a timer with the date set in it
//	if ([insertedObjects count] == 1) {
//		for (Event *event in insertedObjects) {
//		}
//	} else if ([updatedObjects count] == 1) {
//		// We got a updated object, since we only allow one timer this is a running object that got updated for some reason
//		for (Event *event in updatedObjects) {
//		}
//	}
//}

@end
