//
//  EventTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventCell.h"
#import <FontAwesomeKit.h>

@interface EventCell ()

@property (nonatomic) CALayer *selectLayer;

@end

@implementation EventCell

- (void)awakeFromNib {
	self.selectLayer                 = [CALayer layer];
	self.selectLayer.frame           = CGRectMake(self.frontView.layer.bounds.size.width - 10, 0, 10, self.frontView.layer.bounds.size.height);
	self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;

	[self.frontView.layer addSublayer:self.selectLayer];

	CALayer *separatorLayer = [CALayer layer];
	separatorLayer.backgroundColor = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:0.8].CGColor;
	separatorLayer.frame           = CGRectMake(221, 45, 1, 60);

	[self.frontView.layer addSublayer:separatorLayer];

	self.willDelete.font = [FontAwesomeKit fontWithSize:30];
	self.willDelete.text = FAKIconRemove;
}

- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
	if (self.tagPressHandler)
		self.tagPressHandler();
}

- (void)prepareForReuse {
	[self.frontView.layer removeAllAnimations];

	self.frontView.layer.position = self.backView.layer.position;
}

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation {
	if (self.marked == marked)
		return;

	self.marked = marked;

	UIColor *backgroundColor = marked ? [UIColor colorWithWhite:0.251f alpha:1.000] : [UIColor clearColor];

	if (animation) {
		CABasicAnimation *backgroundAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
		backgroundAnimation.fromValue = (id)self.selectLayer.backgroundColor;
		backgroundAnimation.toValue   = (id)backgroundColor.CGColor;
		backgroundAnimation.duration  = 0.4;
		[self.selectLayer addAnimation:backgroundAnimation forKey:@"backgroundColor"];
	}

	self.selectLayer.backgroundColor = backgroundColor.CGColor;
}

@end