//
//  EventTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@interface EventTableViewCell ()

@property (nonatomic) CALayer *separatorLayer;
@property (nonatomic) CALayer *selectLayer;

@end

@implementation EventTableViewCell

- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(cell:tappedTagButton:forEvent:)]) {
        [self.delegate cell:self tappedTagButton:sender forEvent:event];
    }
}

- (void)prepareForReuse {
    self.contentView.alpha = 1;

    [self.layer removeAllAnimations];

    if (self.selectLayer) {
        self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;
    }
}

- (void)drawRect:(CGRect)rect {
    self.separatorLayer                 = [CALayer layer];
    self.separatorLayer.backgroundColor = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:0.8].CGColor;
    self.separatorLayer.frame           = CGRectMake(221, 45, 1, 60);
    [self.layer addSublayer:self.separatorLayer];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    if (!self.selectLayer) {
        self.selectLayer                 = [CALayer layer];
        self.selectLayer.frame           = CGRectMake(self.layer.bounds.size.width - 10, 0, 10, self.layer.bounds.size.height);
        self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:self.selectLayer];
    }

    UIColor *backgroundColor = selected ? [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1] : [UIColor clearColor];

    CABasicAnimation *backgroundAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    backgroundAnimation.fromValue = (id)self.selectLayer.backgroundColor;
    backgroundAnimation.toValue   = (id)backgroundColor.CGColor;
    backgroundAnimation.duration  = 0.4;

    self.selectLayer.backgroundColor = backgroundColor.CGColor;
    [self.selectLayer addAnimation:backgroundAnimation forKey:@"backgroundColor"];
}

@end
