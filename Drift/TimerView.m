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
@property(nonatomic) CAShapeLayer *nowHand;
@property(nonatomic) CAShapeLayer *secondHand;

@end

@implementation TimerView

#pragma mark -
#pragma mark Private properties

@synthesize startHand = _startHand;
@synthesize nowHand = _nowHand;
@synthesize secondHand = _secondHand;

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
    CGMutablePathRef path = CGPathCreateMutable();

    // ticks
    for (NSInteger i=1; i <= 60; ++i)
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

    self.secondHand.bounds = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.height / 2.0 - 16);
    self.secondHand.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.secondHand.anchorPoint = CGPointMake(0.5, 1.0);
	self.secondHand.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * 60, 0, 0, 1);
    self.secondHand.path = path;

    [self.layer addSublayer:self.secondHand];

    // now hand
    self.nowHand = [CAShapeLayer layer];

    path = CGPathCreateMutable();

    // start at top
    CGPathMoveToPoint(path, NULL, 5.0, 17.0);
    // move to bottom left
    CGPathAddLineToPoint(path, NULL, 0.0, 0.0);
    // move to bottom right
    CGPathAddLineToPoint(path, NULL, 9.0, 0.0);
    CGPathCloseSubpath(path);

    self.nowHand.fillColor = [[UIColor colorWithRed:0.098 green:0.800 blue:0.000 alpha:1.000] CGColor];
    self.nowHand.lineWidth = 1.0;

    self.nowHand.bounds = CGRectMake(0.0, 0.0, 9.0, self.bounds.size.height / 2.0 + 22);
    self.nowHand.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.nowHand.anchorPoint = CGPointMake(0.5, 1.0);
	self.nowHand.transform = CATransform3DMakeRotation((M_PI * 2) / 60.0 * 60, 0, 0, 1);
    self.nowHand.path = path;

    [self.layer addSublayer:self.nowHand];
}

#pragma mark -
#pragma mark Public instance methods

- (void)updateForElapsedMilliseconds:(float)milliSeconds
{
    float percentageMilliSecondsIntoMinute = fmodf(milliSeconds, 60000.0) / 60000.0;
	
	int elapsedMinutesSinceStartDate = floor(milliSeconds / 60000.0);
	float percentageMilliSecondsIntoHour = elapsedMinutesSinceStartDate	% 60 / 60.0;
	
    self.secondHand.transform = CATransform3DMakeRotation((M_PI * 2) * percentageMilliSecondsIntoMinute, 0, 0, 1);
    self.nowHand.transform = CATransform3DMakeRotation((M_PI * 2) * percentageMilliSecondsIntoHour, 0, 0, 1);
	
}

@end
