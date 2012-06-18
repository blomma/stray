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

@end

@implementation TimerViewController

@synthesize timerView = _timerView;
@synthesize toggleStartStopButton = _toggleStartStopButton;

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do we have a timer running?
	NSArray *eventArray = [Event MR_findByAttribute:@"running" withValue:[NSNumber numberWithBool:TRUE]];
	if ([eventArray count] == 1) {
		// We have a timer running, fetch it and stop it
		Event *event = [eventArray objectAtIndex:0];
		self.timerView.startDate = event.startDate;
		[self.timerView startUpdates];

		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	}

    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDataModelChange:)
												 name:NSManagedObjectContextObjectsDidChangeNotification
											   object:[NSManagedObjectContext MR_defaultContext]];
}

- (void)viewDidUnload
{
	[self setTimerView:nil];
	[self setToggleStartStopButton:nil];

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)toggleTimer:(id)sender
{
	// Do we have a event that is running
	//	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"running == %@", [NSNumber numberWithBool:TRUE]];
	//	NSNumber *numberOfResults = [Event MR_numberOfEntitiesWithPredicate:predicate];

	NSArray *eventArray = [Event MR_findByAttribute:@"running" withValue:[NSNumber numberWithBool:TRUE]];

	NSDate *now = [NSDate date];
	if ([eventArray count] == 0) {
		// We dont have a timmer running currently
		// create a new one
		Event *event = [Event MR_createEntity];
		event.startDate = now;
		event.runningValue = TRUE;

		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
	} else {
		// We have a timer running, fetch it and stop it
		// We should get one and only one entry from this
		Event *event = [eventArray objectAtIndex:0];
		event.runningValue = FALSE;
		event.stopDate = now;

		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
	}

	[[NSManagedObjectContext MR_defaultContext] MR_save];
}

#pragma mark -
#pragma mark Instance methods

- (void)handleDataModelChange:(NSNotification *)note;
{
    NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];

	// If we got a new Event then start a timer with the date set in it
	if ([insertedObjects count] == 1) {
		for (Event *event in insertedObjects) {
			self.timerView.startDate = event.startDate;
			[self.timerView startUpdates];
		}
	} else if ([updatedObjects count] == 1) {
		// We got a updated object, since we only allow one timer this is a running object that got updated for some reason
		for (Event *event in updatedObjects) {
			[self.timerView stopUpdates];
		}
	}
}

@end
