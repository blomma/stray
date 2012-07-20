//
//  TimerFaceControl.m
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerFaceControl.h"

@interface TimerFaceControl ()

@property (nonatomic) CAShapeLayer *startHand;
@property (nonatomic) CAShapeLayer *minuteHand;
@property (nonatomic) CAShapeLayer *secondHand;
@property (nonatomic) CAShapeLayer *secondHandProgressTicks;

@property (nonatomic) CGFloat minuteHandAngle;
@property (nonatomic) CGFloat secondHandAngle;

@property (nonatomic) CGFloat startHandAngle;
@property (nonatomic) CGFloat startHandDeltaAngle;
@property (nonatomic) CATransform3D startHandTransform;
@property (nonatomic) BOOL isStartHandTransforming;

@end

@implementation TimerFaceControl

#pragma mark -
#pragma mark Public properties

@synthesize startDate = _startDate;
@synthesize nowDate   = _nowDate;
@synthesize stopDate  = _stopDate;

- (void)setStartDate:(NSDate *)startDate {
	_startDate = startDate;

	NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSMinuteCalendarUnit) fromDate:startDate];

	// We want the startHand to have a tick tock behavior, just like the minuteHand
	CGFloat a = (M_PI * 2) * [dateComponents minute] / 60.0;
	if (a != self.startHandAngle) {
		self.startHandAngle      = a;
		self.startHand.transform = CATransform3DMakeRotation(self.startHandAngle, 0, 0, 1);
	}
}

- (void)setNowDate:(NSDate *)nowDate {
	_nowDate = nowDate;

	NSTimeInterval timeInterval   = [self.nowDate timeIntervalSinceDate:self.startDate];
	double elapsedSecondsIntoHour = fmod(timeInterval, 3600);

	// We want fluid updates to the seconds
	CGFloat a = (M_PI * 2) * fmod(elapsedSecondsIntoHour, 60) / 60.0;

	self.secondHandAngle      = a;
	self.secondHand.transform = CATransform3DMakeRotation(self.secondHandAngle, 0, 0, 1);

	// Update the tick marks for the second hand
	int secondsIntoMinute = floor(fmod(elapsedSecondsIntoHour, 60));

	for (int i = 0; i < self.secondHandProgressTicks.sublayers.count; i++) {
		CALayer *layer = [self.secondHandProgressTicks.sublayers objectAtIndex:i];

		if (i < secondsIntoMinute) {
			if (layer.hidden) {
				layer.hidden = NO;
			}
		}
		else  {
			if (!layer.hidden) {
				layer.hidden = YES;
			}
		}
	}

	// And for the minutes we want a more tick/tock behavior
	a = (M_PI * 2) * floor(elapsedSecondsIntoHour / 60) / 60;
	if (a != self.minuteHandAngle) {
		self.minuteHandAngle      = a;
		self.minuteHand.transform = CATransform3DMakeRotation(self.minuteHandAngle, 0, 0, 1);
	}
}

#pragma mark -
#pragma mark Private properties

@synthesize startHand               = _startHand;
@synthesize minuteHand              = _minuteHand;
@synthesize secondHand              = _secondHand;
@synthesize secondHandProgressTicks = _secondHandProgressTicks;

@synthesize startHandAngle          = _startHandAngle;
@synthesize minuteHandAngle         = _minuteHandAngle;
@synthesize secondHandAngle         = _secondHandAngle;

@synthesize startHandDeltaAngle     = _startHandDeltaAngle;
@synthesize startHandTransform      = _startHandTransform;
@synthesize isStartHandTransforming = _isStartHandTransforming;

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		self.startHandAngle          = 0.0;
		self.minuteHandAngle         = 0.0;
		self.secondHandAngle         = 0.0;

		self.startHandDeltaAngle     = 0.0;
		self.isStartHandTransforming = NO;

		[self setUpClock];
	}

	return self;
}

#pragma mark -
#pragma mark Private instance methods

- (void)setUpClock {

	CGMutablePathRef path;
	CGFloat angle;

	// ticks
	for (NSInteger i = 1; i <= 60; ++i) {
		CAShapeLayer *tick = [CAShapeLayer layer];

		path  = CGPathCreateMutable();
		angle = (M_PI * 2) / 60.0 * i;

		if (i % 10 == 0) {
			CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 4.0, 14));

			tick.fillColor   = [[UIColor whiteColor] CGColor];
			tick.lineWidth   = 1;

			tick.bounds      = CGRectMake(0.0, 0.0, 4.0, self.bounds.size.height / 2 - 30);
			tick.anchorPoint = CGPointMake(0.5, 1.0);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
			tick.path        = path;
		}
		else  {
			CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 3.0, 11.0));

			tick.fillColor   = [[UIColor colorWithWhite:0.651 alpha:1.000] CGColor];
			tick.lineWidth   = 1;

			tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.height / 2.0 - 31.5);
			tick.anchorPoint = CGPointMake(0.5, 1.0);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
			tick.path        = path;
		}

		[self.layer addSublayer:tick];
	}

	// minute hand
	self.minuteHand = [CAShapeLayer layer];

	path            = CGPathCreateMutable();

	// start at top
	CGPathMoveToPoint(path, NULL, 5.0, 17.0);
	// move to bottom left
	CGPathAddLineToPoint(path, NULL, 0.0, 0.0);
	// move to bottom right
	CGPathAddLineToPoint(path, NULL, 9.0, 0.0);
	CGPathCloseSubpath(path);

	self.minuteHand.fillColor   = [[UIColor colorWithRed:0.098 green:0.800 blue:0.000 alpha:1.000] CGColor];
	self.minuteHand.lineWidth   = 1.0;

	self.minuteHand.bounds      = CGRectMake(0.0, 0.0, 9.0, self.bounds.size.height / 2.0 - 12);
	self.minuteHand.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.minuteHand.anchorPoint = CGPointMake(0.5, 1.0);
	self.minuteHand.transform   = CATransform3DMakeRotation(self.minuteHandAngle, 0, 0, 1);
	self.minuteHand.path        = path;

	[self.layer addSublayer:self.minuteHand];

	// start hand
	self.startHand = [CAShapeLayer layer];

	path           = CGPathCreateMutable();

	// start at top
	CGPathMoveToPoint(path, NULL, 5, 0.0);
	// move to bottom left
	CGPathAddLineToPoint(path, NULL, 0.0, 17.0);
	// move to bottom right
	CGPathAddLineToPoint(path, NULL, 9.0, 17.0);
	CGPathCloseSubpath(path);

	self.startHand.fillColor   = [[UIColor colorWithRed:1.000 green:0.600 blue:0.008 alpha:1.000] CGColor];
	self.startHand.lineWidth   = 1.0;

	self.startHand.bounds      = CGRectMake(0.0, 0.0, 9.0, self.bounds.size.height / 2 - 50);
	self.startHand.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.startHand.anchorPoint = CGPointMake(0.5, 1.0);
	self.startHand.transform   = CATransform3DMakeRotation(self.startHandAngle, 0, 0, 1);
	self.startHand.path        = path;

	[self.layer addSublayer:self.startHand];

	// second hand
	self.secondHand = [CAShapeLayer layer];

	path            = CGPathCreateMutable();

	// start at top
	CGPathMoveToPoint(path, NULL, 3.5, 0.0);
	// move to bottom left
	CGPathAddLineToPoint(path, NULL, 0.0, 7.0);
	// move to bottom right
	CGPathAddLineToPoint(path, NULL, 7.0, 7.0);
	CGPathCloseSubpath(path);

	self.secondHand.fillColor   = [[UIColor redColor] CGColor];
	self.secondHand.lineWidth   = 1.0;

	self.secondHand.bounds      = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.height / 2.0 - 62);
	self.secondHand.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHand.anchorPoint = CGPointMake(0.5, 1.0);
	self.secondHand.transform   = CATransform3DMakeRotation(self.secondHandAngle, 0, 0, 1);
	self.secondHand.path        = path;

	[self.layer addSublayer:self.secondHand];

	// second hand progress ticks
	self.secondHandProgressTicks             = [CAShapeLayer layer];
	self.secondHandProgressTicks.bounds      = CGRectMake(0.0, 0.0, self.bounds.size.width - 100, self.bounds.size.height - 100);
	self.secondHandProgressTicks.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHandProgressTicks.anchorPoint = CGPointMake(0.5, 0.5);
	[self.layer addSublayer:self.secondHandProgressTicks];

	// paint the second hand tick marks
	for (NSInteger i = 1; i <= 60; ++i) {
		angle = (M_PI * 2) / 60.0 * i;

		CAShapeLayer *tick = [CAShapeLayer layer];
		path = CGPathCreateMutable();

		CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 3.0, 2.0));

		tick.fillColor   = [[UIColor redColor] CGColor];
		tick.lineWidth   = 1;

		tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.secondHandProgressTicks.bounds.size.height / 2);
		tick.anchorPoint = CGPointMake(0.5, 1.0);
		tick.position    = CGPointMake(CGRectGetMidX(self.secondHandProgressTicks.bounds), CGRectGetMidY(self.secondHandProgressTicks.bounds));
		tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
		tick.path        = path;

		[self.secondHandProgressTicks addSublayer:tick];
	}
}

#pragma mark -
#pragma mark Public instance methods

#pragma mark -
#pragma mark UIControl

- (UIControlEvents)allControlEvents {
	return UIControlEventValueChanged;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a;

	self.isStartHandTransforming = NO;

	// Was this a touch on the startHand and is the timer started
	if ([self.startHand.presentationLayer hitTest:point] && self.startDate) {
		self.isStartHandTransforming = YES;

		// Calculate the angle in radians
		cx = self.startHand.position.x;
		cy = self.startHand.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a  = atan2(dy,dx);

		// Save them for later use
		self.startHandDeltaAngle = a;   //+ M_PI_2;
		self.startHandTransform  = self.startHand.transform;

		[self sendActionsForControlEvents:UIControlEventValueChanged];

		return YES;
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return NO;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a, da;

	// What are we tracking
	if (self.isStartHandTransforming) {
		// TODO: Check constraint, the starHand can't go
		// further than the current time

		// Calculate the angle in radians
		cx = self.startHand.position.x;
		cy = self.startHand.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a  = atan2(dy,dx);
		da = self.startHandDeltaAngle - a;

		[CATransaction begin];
		[CATransaction setDisableActions:YES];

		self.startHand.transform = CATransform3DRotate(self.startHandTransform, -da, 0, 0, 1);

		[CATransaction commit];
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	// We need to snap the startHand to the closest minute

	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
}

#pragma mark -
#pragma mark UIView

@end
