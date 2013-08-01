//
//  AIStyle.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-06-24.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "AIStyle.h"
#import "TagFilterButton.h"

@implementation AIStyle

+ (void)applyStyle {
	//==================================================================================//
	// Shared
	//==================================================================================//
	NSString *primaryFont = @"HelveticaNeue";

	//==================================================================================//
	// UIButton
	//==================================================================================//
    [[TagFilterButton appearance] setTitleFont:[UIFont fontWithName:primaryFont size:12]];
    [[TagFilterButton appearance] setTitleBackgroundColor:[UIColor clearColor]];
    [[TagFilterButton appearance] setTitleColor:[UIColor colorWithRed:1.000f green:0.000f blue:0.318f alpha:1]];
    [[TagFilterButton appearance] setSelectedTitleColor:[UIColor colorWithWhite:0.251f alpha:1.000]];
    [[TagFilterButton appearance] setBackgroundColor:[UIColor clearColor]];
    [[TagFilterButton appearance] setSelectedColor:[UIColor colorWithWhite:0.251f alpha:1.000]];
    [[TagFilterButton appearance] setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 5)];

	//==================================================================================//
	// RootViewController
	//==================================================================================//
//	[[UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil] setBackgroundColor:[UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:0]];
//	[[UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil] setCurrentPageIndicatorTintColor:[UIColor colorWithWhite:0.267f alpha:0.8f]];
//	[[UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil] setPageIndicatorTintColor:[UIColor colorWithWhite:0.267f alpha:0.2f]];
}

@end
