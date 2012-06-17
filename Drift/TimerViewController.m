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

@synthesize clock;

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
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(handleDataModelChange:) 
												 name:NSManagedObjectContextObjectsDidChangeNotification 
											   object:[NSManagedObjectContext MR_defaultContext]];
}

- (void)viewDidUnload
{
	[self setClock:nil];

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)startTimer:(id)sender {
	Event *event = [Event MR_createEntity];
	event.startDate = [NSDate date];
	
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
			[self.clock startUpdates];
		}
	}
}

@end
