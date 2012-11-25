//
//  TagButton.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-21.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagButton.h"

#import <QuartzCore/QuartzCore.h>

@interface TagButton ()

@property (nonatomic) CALayer *titleBackground;

@end

@implementation TagButton

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }

    return self;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    if ([title isEqualToString:@""]) {
        title = @"‒‒ ‒‒";
    }

    [super setTitle:title forState:state];
}

#pragma mark -
#pragma mark Private methods

- (void)renderBackground {
    CGRect frame = self.titleLabel.layer.frame;

    frame.origin.x -= 6;
    frame.size.width += 12;

    frame.origin.y -= 1;
    frame.size.height += 1;

    if ([self.currentTitle isEqualToString:@""]) {
        frame.size.width = 30;
    }

    self.titleBackground.frame = frame;

    if ([self.currentTitle isEqualToString:@""]) {
        CGFloat x = CGRectGetMidX(self.titleLabel.frame);
        CGPoint position = CGPointMake(x, self.titleLabel.layer.position.y);

        self.titleBackground.position = position;
    }
}

@end
