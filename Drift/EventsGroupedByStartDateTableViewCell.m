//
//  EventTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventsGroupedByStartDateTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation EventsGroupedByStartDateTableViewCell

- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    self.didDeleteEventHandler(self);
}

- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
    self.didEditTagHandler(self);
}

- (void)prepareForReuse {
    [self marked:NO withAnimation:NO];
    
    self.frontViewLeading.constant = 0;
    self.frontViewTrailing.constant = 0;
}

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation {
    if (self.marked == marked) {
        return;
    }
    
    self.marked = marked;
    
    UIColor *backgroundColor = marked ? [UIColor colorWithWhite:0.251f alpha:1.000] : [UIColor clearColor];
    
    if (animation) {
        CABasicAnimation *backgroundAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        backgroundAnimation.fromValue = (id)self.rightSelected.backgroundColor.CGColor;
        backgroundAnimation.toValue   = (id)backgroundColor.CGColor;
        backgroundAnimation.duration  = 0.4;
        [self.rightSelected.layer addAnimation:backgroundAnimation forKey:@"backgroundColor"];
    }
    
    self.rightSelected.layer.backgroundColor = backgroundColor.CGColor;
}

@end
