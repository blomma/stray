//
//  CustomPagerViewController.m
//  Dift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

@synthesize managedObjectContext = _managedObjectContext;

- (void)viewDidLoad 
{
	// Do any additional setup after loading the view, typically from a nib.
    [super viewDidLoad];

	[self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"TimerView"]];
	[self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"TimerArchiveView"]];
}

@end