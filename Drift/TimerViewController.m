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
	if ([self.currentEvent runningValue])
	{
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat: @"yyyy-MM-dd HH:mm"];
		self.startDateLabel.text = [formatter stringFromDate:self.currentEvent.startDate];

		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	} else {
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do we have a running event
	NSArray *eventArray = [Event MR_findByAttribute:@"running" withValue:[NSNumber numberWithBool:TRUE]];
	if ([eventArray count] == 1) {
		self.currentEvent = [eventArray objectAtIndex:0];
	}

	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
														target:self
													  selector:@selector(timerUpdate)
													  userInfo:nil
													   repeats:YES];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(handleDataModelChange:)
//												 name:NSManagedObjectContextObjectsDidChangeNotification
//											   object:[NSManagedObjectContext MR_defaultContext]];
}

- (void)viewDidUnload
{
	[self setTimerView:nil];
	[self setToggleStartStopButton:nil];

    [self setStartDateLabel:nil];
    [self setRunningTimeLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)toggleTimer:(id)sender
{
	// Do we have a event that is running
	if (![self.currentEvent runningValue]) {
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
	} else {
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
		[self.timerView updateForElapsedMilliseconds:timeInterval * 1000.0];

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
