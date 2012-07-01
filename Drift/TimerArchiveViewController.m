//
//  TimerArchiveViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerArchiveViewController.h"
#import "Event.h"

@interface TimerArchiveViewController ()

@property(nonatomic, strong) NSMutableArray *timerEvents;

@end

@implementation TimerArchiveViewController

#pragma mark -
#pragma mark private properties

@synthesize timerEvents = _timerEvents;

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
	
	// Get starting list
	self.timerEvents = [NSMutableArray new];
	[self.timerEvents addObjectsFromArray:[Event MR_findAllSortedBy:@"startDate" ascending:NO]];

	// Get notified of new things happening
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDataModelChange:)
												 name:NSManagedObjectContextObjectsDidChangeNotification
											   object:[NSManagedObjectContext MR_defaultContext]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)handleDataModelChange:(NSNotification *)note;
{
    NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];

	if ([insertedObjects count] > 0) {
		NSMutableArray *array = [NSMutableArray arrayWithArray:[insertedObjects allObjects]];
		[array sortUsingSelector:@selector(compare:)];
		
		[self.tableView beginUpdates];
		
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
		
		for (Event *event in array)
		{
			[self.timerEvents insertObject:event atIndex:0];
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] 
								  withRowAnimation:UITableViewRowAnimationTop];
		}
		
		[self.tableView endUpdates];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.timerEvents.count;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	// Section title is the region name
	return @"test";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TimerEventCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
