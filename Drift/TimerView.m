//
//  TimerView.m
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerView.h"

@interface TimerView ()

@property(nonatomic) CAShapeLayer *startHand;
@property(nonatomic) CAShapeLayer *minuteHand;
@property(nonatomic) CAShapeLayer *secondHand;
@property(nonatomic) CAShapeLayer *secondHandProgressTicks;

- (void)updateSecondTickMarksForElapsedSecondsIntoMinute:(double)seconds;

@end

@implementation TimerView

#pragma mark -
#pragma mark Private properties

@synthesize startHand = _startHand;
@synthesize minuteHand = _minuteHand;
@synthesize secondHand = _secondHand;
@synthesize secondHandProgressTicks = _secondHandProgressTicks;

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self setUpClock];
    }

    return self;
}

#pragma mark -
#pragma mark Private instance methods

- (void)setUpClock
{
    CGMutablePathRef path;

    // ticks
    for (NSInteger i = 1; i <= 60; ++i)
	{
        CAShapeLayer *tick = [CAShapeLayer layer];
        path = CGPathCreateMutable();

		if (i % 10 == 0) {
			CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 4.0, 14.0));

			tick.fillColor = [[UIColor whiteColor] CGColor];
			tick.lineWidth = 1;

			tick.bounds = CGRectMake(0.0, 0.0, 4.0, self.bounds.size.height / 2.0 + 1.5);
			tick.anchorPoint = CGPointMake(0.5, 1.0);
			tick.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * i, 0, 0, 1);
			tick.path = path;
		} else {
			CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 3.0, 11.0));

			tick.fillColor = [[UIColor colorWithWhite:0.651 alpha:1.000] CGColor];
			tick.lineWidth = 1;

			tick.bounds = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.height / 2.0);
			tick.anchorPoint = CGPointMake(0.5, 1.0);
			tick.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * i, 0, 0, 1);
			tick.path = path;
		}

        [self.layer addSublayer:tick];
    }

    // second hand
    self.secondHand = [CAShapeLayer layer];

    path = CGPathCreateMutable();

    // start at top
    CGPathMoveToPoint(path, NULL, 3.5, 0.0);
    // move to bottom left
    CGPathAddLineToPoint(path, NULL, 0.0, 7.0);
    // move to bottom right
    CGPathAddLineToPoint(path, NULL, 7.0, 7.0);
    CGPathCloseSubpath(path);

    self.secondHand.fillColor = [[UIColor redColor] CGColor];
    self.secondHand.lineWidth = 1.0;

    self.secondHand.bounds = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.height / 2.0 - 26);
    self.secondHand.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.secondHand.anchorPoint = CGPointMake(0.5, 1.0);
	self.secondHand.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * 60, 0, 0, 1);
    self.secondHand.path = path;

    [self.layer addSublayer:self.secondHand];

	// second hand progress ticks
	self.secondHandProgressTicks = [CAShapeLayer layer];
    self.secondHandProgressTicks.bounds = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.height - 40);
    self.secondHandProgressTicks.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.secondHandProgressTicks.anchorPoint = CGPointMake(0.5, 0.5);
	[self.layer addSublayer:self.secondHandProgressTicks];

	// paint the second hand tick marks
    for (NSInteger i = 1; i <= 60; ++i)
	{
		CAShapeLayer *tick = [CAShapeLayer layer];
		path = CGPathCreateMutable();
		
		CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 3.0, 2.0));
		
		tick.fillColor = [[UIColor redColor] CGColor];
		tick.lineWidth = 1;
		
		tick.bounds = CGRectMake(0.0, 0.0, 3.0, self.secondHandProgressTicks.bounds.size.height / 2.0);
		tick.anchorPoint = CGPointMake(0.5, 1.0);
		tick.position = CGPointMake(CGRectGetMidX(self.secondHandProgressTicks.bounds), CGRectGetMidY(self.secondHandProgressTicks.bounds));
		tick.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * i, 0, 0, 1);
		tick.path = path;
		
		[self.secondHandProgressTicks addSublayer:tick];
	}

    // minute hand
    self.minuteHand = [CAShapeLayer layer];

    path = CGPathCreateMutable();

    // start at top
    CGPathMoveToPoint(path, NULL, 5.0, 17.0);
    // move to bottom left
    CGPathAddLineToPoint(path, NULL, 0.0, 0.0);
    // move to bottom right
    CGPathAddLineToPoint(path, NULL, 9.0, 0.0);
    CGPathCloseSubpath(path);

    self.minuteHand.fillColor = [[UIColor colorWithRed:0.098 green:0.800 blue:0.000 alpha:1.000] CGColor];
    self.minuteHand.lineWidth = 1.0;

    self.minuteHand.bounds = CGRectMake(0.0, 0.0, 9.0, self.bounds.size.height / 2.0 + 22);
    self.minuteHand.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.minuteHand.anchorPoint = CGPointMake(0.5, 1.0);
	self.minuteHand.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * 60, 0, 0, 1);
    self.minuteHand.path = path;

    [self.layer addSublayer:self.minuteHand];
}

- (void)updateSecondTickMarksForElapsedSecondsIntoMinute:(double)seconds
{
	int secondsIntoMinute = floor(fmod(seconds, 60));
	
	int i = 1;
	for (CALayer *layer in self.secondHandProgressTicks.sublayers)
	{
		if (i <= secondsIntoMinute) {
			layer.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * i, 0, 0, 1);
			layer.hidden = FALSE;
		} else {
			layer.hidden = TRUE;
		}
		
		i++;
	}
}

#pragma mark -
#pragma mark Public instance methods

- (void)updateForElapsedSecondsIntoHour:(double)seconds
{
	// We want fluid updates to the seconds
    double percentageSecondsIntoMinute = fmod(seconds, 60) / 60.0;

	// And for the minutes we want a more tick/tock behavior
	double percentageMinutesIntoHour = floor(seconds / 60) / 60;

    self.secondHand.transform = CATransform3DMakeRotation((M_PI * 2) * percentageSecondsIntoMinute, 0, 0, 1);
    self.minuteHand.transform = CATransform3DMakeRotation((M_PI * 2) * percentageMinutesIntoHour, 0, 0, 1);

	[self updateSecondTickMarksForElapsedSecondsIntoMinute:seconds];
}

@end
