//
//  EventTimerControl.m
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventTimerControl.h"
#import "NoHitCAShapeLayer.h"

@interface EventTimerControl ()

@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) CAShapeLayer *startLayer;
@property (nonatomic) CAShapeLayer *nowLayer;
@property (nonatomic) NoHitCAShapeLayer *secondLayer;
@property (nonatomic) NoHitCAShapeLayer *secondProgressTicksLayer;
@property (nonatomic) Event *event;

// Touch transforming
@property (nonatomic) NSDate *deltaDate;
@property (nonatomic) CGFloat deltaAngle;
@property (nonatomic) CATransform3D deltaTransform;
@property (nonatomic) CAShapeLayer *deltaLayer;

// Caches
@property (nonatomic) CGFloat previousSecondTick;
@property (nonatomic) CGFloat previousNow;

@end

@implementation EventTimerControl

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self)
		[self drawClockFace];

	return self;
}

#pragma mark -
#pragma mark Public methods

- (void)startWithEvent:(Event *)event {
	self.transforming = EventTimerNotTransforming;

	self.previousSecondTick = -1;
	self.previousNow        = -1;

	[self.updateTimer invalidate];

	self.event = event;

	self.startDate = event.startDate;
	[self drawStart];

	if ([event isActive])
		self.nowDate = [NSDate date];
	else
		self.nowDate  = event.stopDate;

	[self drawNow];

	if ([event isActive])
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
		                                                    target:self
		                                                  selector:@selector(timerUpdate)
		                                                  userInfo:nil
		                                                   repeats:YES];
}

- (void)paus {
	[self.updateTimer invalidate];
}

- (void)stop {
	[self.updateTimer invalidate];
}

- (void)reset {
	[self.updateTimer invalidate];

	self.event = nil;

	self.secondLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
	self.startLayer.transform  = CATransform3DMakeRotation(0, 0, 0, 1);
	self.nowLayer.transform    = CATransform3DMakeRotation(0, 0, 0, 1);

	for (NSUInteger i = 0; i < self.secondProgressTicksLayer.sublayers.count; i++) {
		NoHitCAShapeLayer *layer = [self.secondProgressTicksLayer.sublayers objectAtIndex:i];
		layer.hidden = NO;
	}
}

#pragma mark -
#pragma mark Private methods

- (NSTimeInterval)angleToTimeInterval:(CGFloat)a {
	return ((a / (2 * M_PI)) * 3600);
}

- (CGFloat)deltaBetweenAngleA:(CGFloat)a AngleB:(CGFloat)b {
	CGFloat difference = b - a;

	while (difference < -M_PI) {
		difference += 2 * M_PI;
	}
	while (difference > M_PI) {
		difference -= 2 * M_PI;
	}

	return difference;
}

- (void)timerUpdate {
	self.nowDate = [NSDate date];
	[self drawNow];
}

- (void)drawStart {
	NSTimeInterval startSeconds = [self.startDate timeIntervalSince1970];

	CGFloat a = (CGFloat)((M_PI * 2) * floor(fmod(startSeconds, 3600) / 60) / 60);
	self.startLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);
}

- (void)drawNow {
	NSTimeInterval nowSeconds = [self.nowDate timeIntervalSince1970];

	// We want fluid updates to the seconds
	double secondsIntoMinute = fmod(nowSeconds, 60);

	CGFloat a = (CGFloat)(M_PI * 2 * (secondsIntoMinute / 60));
	self.secondLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);

	// Update the tick marks for the seconds
	CGFloat secondTick = (CGFloat)floor(secondsIntoMinute);

	if (fabs(secondTick) != fabs(self.previousSecondTick)) {
		for (NSUInteger i = 0; i < self.secondProgressTicksLayer.sublayers.count; i++) {
			NoHitCAShapeLayer *layer = [self.secondProgressTicksLayer.sublayers objectAtIndex:i];

			if (i < secondTick)
				layer.hidden = NO;
			else
				layer.hidden = YES;
		}

		self.previousSecondTick = secondTick;
	}


	double secondsIntoHour = fmod(nowSeconds, 3600);

	// And for the minutes we want a more tick/tock behavior
	a = (CGFloat)(M_PI * 2 * (floor(secondsIntoHour / 60) / 60));
	if (fabs(a) != fabs(self.previousNow)) {
		self.nowLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);
		self.previousNow        = a;
	}
}

- (void)drawClockFace {
	CGFloat angle;

	if ([self.layer respondsToSelector:@selector(setContentsScale:)])
		[self.layer setContentsScale:[[UIScreen mainScreen] scale]];

	// =====================
	// = Ticks initializer =
	// =====================
	UIBezierPath *largeTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 5.0, 14)];
	UIBezierPath *smallTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 11.0)];

	for (NSInteger i = 1; i <= 60; ++i) {
		NoHitCAShapeLayer *tick = [NoHitCAShapeLayer layer];
		if ([tick respondsToSelector:@selector(setContentsScale:)])
			[tick setContentsScale:[[UIScreen mainScreen] scale]];

		angle = (CGFloat)((M_PI * 2) / 60.0 * i);

		if (i % 10 == 0) {
			// position
			tick.bounds      = CGRectMake(0.0, 0.0, 5.0, self.bounds.size.width / 2 - 30);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.anchorPoint = CGPointMake(0.5, 1.0);

			// drawing
			tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
			tick.fillColor = [[UIColor colorWithWhite:0.167 alpha:1.000] CGColor];
			tick.lineWidth = 1;
			tick.path      = largeTickPath.CGPath;
		} else {
			// position
			tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.width / 2.0 - 31.5);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.anchorPoint = CGPointMake(0.5, 1.0);

			// drawing
			tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
			tick.fillColor = [[UIColor colorWithWhite:0.292 alpha:1.000] CGColor];
			tick.lineWidth = 1;
			tick.path      = smallTickPath.CGPath;
		}

		[self.layer addSublayer:tick];
	}

	// ==========================
	// = Now initializer =
	// ==========================
	self.nowLayer = [CAShapeLayer layer];
	if ([self.nowLayer respondsToSelector:@selector(setContentsScale:)])
		[self.nowLayer setContentsScale:[[UIScreen mainScreen] scale]];

	// We make the bounds larger for the hit test, otherwise the target is
	// to damn small for human hands, martians not included
	UIBezierPath *nowHandPath = [UIBezierPath bezierPath];
	[nowHandPath moveToPoint:CGPointMake(15, 17)];   // Start at the top
	[nowHandPath addLineToPoint:CGPointMake(10, 0)];  // Move to bottom left
	[nowHandPath addLineToPoint:CGPointMake(20, 0)]; // Move to bottom right

	// position
	self.nowLayer.bounds      = CGRectMake(0.0, 0.0, 30, 30);
	self.nowLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.nowLayer.anchorPoint = CGPointMake(0.5, 5.2);

	// drawing
	self.nowLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
	self.nowLayer.fillColor = [[UIColor colorWithRed:0.427 green:0.784 blue:0.992 alpha:1] CGColor];
	self.nowLayer.lineWidth = 1.0;
	self.nowLayer.path      = nowHandPath.CGPath;

	[self.layer addSublayer:self.nowLayer];

	// =========================
	// = Start initializer =
	// =========================
	self.startLayer = [CAShapeLayer layer];
	if ([self.startLayer respondsToSelector:@selector(setContentsScale:)])
		[self.startLayer setContentsScale:[[UIScreen mainScreen] scale]];

	// We make the bounds larger for the hit test, otherwise the target is
	// to damn small for human hands, martians not included
	UIBezierPath *startHandPath = [UIBezierPath bezierPath];
	[startHandPath moveToPoint:CGPointMake(15, 17)];   // Start at the top
	[startHandPath addLineToPoint:CGPointMake(10, 0)];  // Move to bottom left
	[startHandPath addLineToPoint:CGPointMake(20, 0)]; // Move to bottom right

	// position
	self.startLayer.bounds      = CGRectMake(0.0, 0.0, 30, 30);
	self.startLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.startLayer.anchorPoint = CGPointMake(0.5, 5.2);

	// drawing
	self.startLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
	self.startLayer.fillColor = [[UIColor colorWithRed:0.941 green:0.686 blue:0.314 alpha:1] CGColor];
	self.startLayer.lineWidth = 1.0;
	self.startLayer.path      = startHandPath.CGPath;

	[self.layer addSublayer:self.startLayer];

	// ==========================
	// = Second initializer =
	// ==========================
	self.secondLayer = [NoHitCAShapeLayer layer];
	if ([self.secondLayer respondsToSelector:@selector(setContentsScale:)])
		[self.secondLayer setContentsScale:[[UIScreen mainScreen] scale]];

	UIBezierPath *secondHandPath = [UIBezierPath bezierPath];
	[secondHandPath moveToPoint:CGPointMake(3.5, 0)];  // Start at the top
	[secondHandPath addLineToPoint:CGPointMake(0, 7)]; // Move to bottom left
	[secondHandPath addLineToPoint:CGPointMake(7, 7)]; // Move to bottom right

	// position
	self.secondLayer.bounds      = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.width / 2.0 - 62);
	self.secondLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondLayer.anchorPoint = CGPointMake(0.5, 1.0);

	// drawing
	self.secondLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
	self.secondLayer.fillColor = [[UIColor colorWithRed:0.843 green:0.306 blue:0.314 alpha:1] CGColor];
	self.secondLayer.lineWidth = 1.0;
	self.secondLayer.path      = secondHandPath.CGPath;

	[self.layer addSublayer:self.secondLayer];

	// =========================================
	// = Second progress ticks initializer =
	// =========================================
	self.secondProgressTicksLayer = [NoHitCAShapeLayer layer];
	if ([self.secondProgressTicksLayer respondsToSelector:@selector(setContentsScale:)])
		[self.secondProgressTicksLayer setContentsScale:[[UIScreen mainScreen] scale]];

	// position
	self.secondProgressTicksLayer.bounds      = CGRectMake(0.0, 0.0, self.bounds.size.width - 100, self.bounds.size.width - 100);
	self.secondProgressTicksLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondProgressTicksLayer.anchorPoint = CGPointMake(0.5, 0.5);

	[self.layer addSublayer:self.secondProgressTicksLayer];

	UIBezierPath *secondHandTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 2.0)];
	for (NSInteger i = 1; i <= 60; ++i) {
		angle = (CGFloat)((M_PI * 2) / 60.0 * i);

		NoHitCAShapeLayer *tick = [NoHitCAShapeLayer layer];
		if ([tick respondsToSelector:@selector(setContentsScale:)])
			[tick setContentsScale:[[UIScreen mainScreen] scale]];

		// position
		tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.secondProgressTicksLayer.bounds.size.width / 2);
		tick.position    = CGPointMake(CGRectGetMidX(self.secondProgressTicksLayer.bounds), CGRectGetMidY(self.secondProgressTicksLayer.bounds));
		tick.anchorPoint = CGPointMake(0.5, 1.0);

		// drawing
		tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
		tick.fillColor = [[UIColor colorWithRed:0.843 green:0.306 blue:0.314 alpha:1] CGColor];
		tick.lineWidth = 1;
		tick.path      = secondHandTickPath.CGPath;

		[self.secondProgressTicksLayer addSublayer:tick];
	}
}

#pragma mark -
#pragma mark UIControl

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	if (!self.event)
		return NO;

	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a;

	self.deltaLayer = nil;

	if ([self.startLayer.presentationLayer hitTest:point]) {
		self.deltaLayer = self.startLayer;
		self.deltaDate  = self.startDate;

		self.transforming = EventTimerStartDateTransformingStart;

		[self.updateTimer invalidate];
	} else if ([self.nowLayer.presentationLayer hitTest:point] && ![self.event isActive]) {
		self.deltaLayer = self.nowLayer;
		self.deltaDate  = self.nowDate;

		self.transforming = EventTimerNowDateTransformingStart;
	}

	if (self.deltaLayer != nil) {
		// Calculate the angle in radians
		cx = self.deltaLayer.position.x;
		cy = self.deltaLayer.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a = (CGFloat)atan2(dy, dx);

		// Save them away for future iteration
		self.deltaAngle     = a;
		self.deltaTransform = self.deltaLayer.transform;
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return self.deltaLayer != nil;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a, da;

	if (self.deltaLayer != nil) {
		// Calculate the angle in radians
		cx = self.deltaLayer.position.x;
		cy = self.deltaLayer.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a  = (CGFloat)atan2(dy, dx);
		da = [self deltaBetweenAngleA:self.deltaAngle AngleB:a];

		// The deltaangle applied to the transform
		CATransform3D transform = CATransform3DRotate(self.deltaTransform, da, 0, 0, 1);

		// Save for next iteration
		self.deltaAngle     = a;
		self.deltaTransform = transform;

		// If we are tracking the start  then
		// we cant move past the now
		if (self.deltaLayer == self.startLayer) {
			CGFloat seconds = (CGFloat)[self angleToTimeInterval : da];

			NSDate *startDate = [self.deltaDate dateByAddingTimeInterval:seconds];
			self.deltaDate = startDate;

			if ([[startDate laterDate:self.nowDate] isEqualToDate:startDate]) {
				startDate = self.nowDate;
				transform = self.nowLayer.transform;
			}

			self.startDate = startDate;
		} else if (self.deltaLayer == self.nowLayer) {
			CGFloat seconds = (CGFloat)[self angleToTimeInterval : da];

			NSDate *nowDate = [self.deltaDate dateByAddingTimeInterval:seconds];
			self.deltaDate = nowDate;

			if ([[nowDate earlierDate:self.startDate] isEqualToDate:nowDate]) {
				nowDate   = self.startDate;
				transform = self.startLayer.transform;
			}

			self.nowDate  = nowDate;
		}

		[CATransaction begin];
		[CATransaction setDisableActions:YES];

		self.deltaLayer.transform = transform;

		[CATransaction commit];
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return self.deltaLayer != nil;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	if (self.deltaLayer != nil) {
		// If we are tracking the start then
		// we want to move the start to it's start position
		if (self.deltaLayer == self.startLayer) {
			[self drawStart];

			self.transforming = EventTimerStartDateTransformingStop;

			// Resume the passing of time
			if (![self.updateTimer isValid] && [self.event isActive])
				self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
				                                                    target:self
				                                                  selector:@selector(timerUpdate)
				                                                  userInfo:nil
				                                                   repeats:YES];
		} else if (self.deltaLayer == self.nowLayer) {
			[self drawNow];

			self.transforming = EventTimerNowDateTransformingStop;
		}

		self.deltaLayer = nil;
	}

	self.transforming = EventTimerNotTransforming;

	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
