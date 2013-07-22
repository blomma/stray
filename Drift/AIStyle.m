//
//  AIStyle.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-06-24.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "AIStyle.h"

@implementation AIStyle

+ (void)applyStyle {
	//==================================================================================//
	// RootViewController
	//==================================================================================//
	[[UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil] setBackgroundColor:[UIColor colorWithRed:0.941f green:0.933f blue:0.925f alpha:1]];
	[[UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil] setCurrentPageIndicatorTintColor:[UIColor colorWithWhite:0.267f alpha:0.8f]];
	[[UIPageControl appearanceWhenContainedIn:[UIPageViewController class], nil] setPageIndicatorTintColor:[UIColor colorWithWhite:0.267f alpha:0.2f]];
}

@end
