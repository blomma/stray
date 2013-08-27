//
//  PreferenceAnimationController.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-08-25.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "PreferenceAnimationController.h"

@implementation PreferenceAnimationController

- (id)init {
    self = [super init];
    if (self) {
    }
    
    return self;
}

#pragma mark -
#pragma mark UIViewControllerAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIView *inView = [transitionContext containerView];
    UIView *toView = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey].view;
    UIView *fromView = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey].view;

    if (self.isDismissed) {
        UIView *preferenceOverlay = [inView viewWithTag:1];

        [UIView animateWithDuration:0.4
                              delay:0 options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            fromView.center = CGPointMake(-CGRectGetMidX(inView.frame), CGRectGetMidY(inView.frame));
            preferenceOverlay.alpha = 0;
        } completion:^(BOOL finished) {
            [preferenceOverlay removeFromSuperview];
            [fromView removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    } else {
        UIView *preferenceOverlay = [self createOverlayViewWithFrame:inView.frame];
        [inView addSubview:preferenceOverlay];

        toView.center = CGPointMake(-CGRectGetMidX(inView.frame), CGRectGetMidY(inView.frame));
        [inView addSubview:toView];

        [UIView animateWithDuration:1
                              delay:0
             usingSpringWithDamping:0.7f
              initialSpringVelocity:2.3f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             preferenceOverlay.alpha = 0.8;
                             toView.center = CGPointMake(toView.center.x + 200, CGRectGetMidY(inView.frame));
                         } completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 1;
}

#pragma mark -
#pragma mark Private methods

- (UIView *)createOverlayViewWithFrame:(CGRect)frame {
    UIView *preferenceOverlay = [[UIView alloc] initWithFrame:frame];
    preferenceOverlay.alpha = 0;
    preferenceOverlay.userInteractionEnabled = NO;
    preferenceOverlay.tag = 1;

    return preferenceOverlay;
}

@end
