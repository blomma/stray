//
//  RootViewController.m
//  Dift
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "RootViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
	// Do any additional setup after loading the view, typically from a nib.
	[super viewDidLoad];

	[self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"EventViewController"]];
	[self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"EventGroupsViewController"]];
}

@end
