//
//  UIPageViewController+UIPageViewController_UIPageControl.m
//  Drift
//
//  Created by Mikael Hultgren on 9/18/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "UIPageViewController+UIPageControl.h"

@implementation UIPageViewController (UIPageControl)

- (UIPageControl *)pageControl {
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UIPageControl class]]) {
            return (UIPageControl *)view;
        }
    }

    return nil;
}

@end
