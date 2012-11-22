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
        self.titleBackground = [CALayer layer];
        self.titleBackground.backgroundColor = [[UIColor colorWithWhite:0.392 alpha:1.000] CGColor];
        self.titleBackground.cornerRadius = 6;

        [self.layer insertSublayer:self.titleBackground below:self.titleLabel.layer];
    }

    return self;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    [super setTitle:title forState:state];

    [self renderBackground];
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
