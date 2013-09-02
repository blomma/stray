//
//  EventTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventCell.h"

@interface EventCell ()

@property (weak, nonatomic) IBOutlet UIView *selection;

@end

@implementation EventCell

- (void)awakeFromNib {
	//-------------------------------------
	/// time container
	//-------------------------------------
    UIColor *colorOne = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:0.3f];
	UIColor *colorTwo = [UIColor colorWithRed:0.851f green:0.851f blue:0.835f alpha:1];

	NSArray *colors = @[(id)colorOne.CGColor, (id)colorTwo.CGColor, (id)colorTwo.CGColor, (id)colorOne.CGColor];
	NSArray *locations = @[@0.0, @0.4, @0.6, @1.0];

	CAGradientLayer *barrier = [CAGradientLayer layer];
	barrier.colors     = colors;
	barrier.locations  = locations;
	barrier.startPoint = CGPointMake(0, 0.5);
	barrier.endPoint   = CGPointMake(1.0, 0.5);

	barrier.bounds = CGRectMake(0, 0, self.timeContainer.bounds.size.width, 0.5);
	barrier.position    = CGPointMake(self.timeContainer.layer.position.x, 0);
	barrier.anchorPoint = self.timeContainer.layer.anchorPoint;

	[self.timeContainer.layer addSublayer:barrier];

	//-------------------------------------
	/// tag container
	//-------------------------------------
	barrier = [CAGradientLayer layer];
	barrier.colors     = colors;
	barrier.locations  = locations;
	barrier.startPoint = CGPointMake(0, 0.5);
	barrier.endPoint   = CGPointMake(1.0, 0.5);

	barrier.bounds = CGRectMake(0, 0, self.tagContainer.bounds.size.width, 0.5);
	barrier.position    = CGPointMake(self.tagContainer.layer.position.x, self.tagContainer.bounds.size.height);
	barrier.anchorPoint = self.tagContainer.layer.anchorPoint;

	[self.tagContainer.layer addSublayer:barrier];
}

- (void)prepareForReuse {
    self.selection.backgroundColor = [UIColor clearColor];
}

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation {
	if (self.marked == marked)
		return;

	self.marked = marked;

	UIColor *backgroundColor = marked ? [UIColor colorWithWhite:0.251f alpha:1.000] : [UIColor clearColor];

    if (animation) {
        [UIView animateWithDuration:0.4f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.selection.backgroundColor = backgroundColor;
        } completion:nil];
    } else {
        self.selection.backgroundColor = backgroundColor;
    }
}

- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
    if (self.didSelectTagHandler) {
        self.didSelectTagHandler();
    }
}

@end
