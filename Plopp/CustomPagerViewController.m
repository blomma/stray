//
//  CustomPagerViewController.m
//  Plopp
//
//  Created by Mikael Hultgren on 5/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CustomPagerViewController.h"

@interface CustomPagerViewController ()

@end

@implementation CustomPagerViewController

- (void)viewDidLoad
{
	// Do any additional setup after loading the view, typically from a nib.
    [super viewDidLoad];
    
	[self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"TimerView"]];
	[self addChildViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"View2"]];
}

@end