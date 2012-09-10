//
//  EventTimerControl.m
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventDataManager.h"
#import "EventTimerControl.h"
#import <QuartzCore/QuartzCore.h>
#import "NoHitCAShapeLayer.h"

@interface EventTimerControl ()

@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) CAShapeLayer *startHandLayer;
@property (nonatomic) CAShapeLayer *nowHandLayer;
@property (nonatomic) NoHitCAShapeLayer *secondHandLayer;
@property (nonatomic) NoHitCAShapeLayer *secondHandProgressTicksLayer;
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

#pragma mark -
#pragma mark Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
        [self drawClockFace];
	}

	return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.updateTimer invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
	if ([self.event isActive]) {
		if (![self.updateTimer isValid]) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
			                                                    target:self
			                                                  selector:@selector(timerUpdate)
			                                                  userInfo:nil
			                                                   repeats:YES];
		}

		[self.updateTimer fire];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Public methods

- (void)startWithEvent:(Event *)event {
    [self prepareForReuse];

    self.event = event;

    self.startDate = event.startDate;
    [self drawStart];

    if (![event isActive]) {
        self.nowDate = event.stopDate;
        self.stopDate = event.stopDate;
    } else {
        self.nowDate = [NSDate date];
    }

	[self drawNow];

    if ([event isActive]) {
        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                            target:self
                                                          selector:@selector(timerUpdate)
                                                          userInfo:nil
                                                           repeats:YES];
    }
}

- (void)stop {
	[self.updateTimer invalidate];

	self.nowDate  = self.event.stopDate;
	self.stopDate = self.event.stopDate;

	[self drawNow];
}

- (void)reset {
	[self.updateTimer invalidate];

	self.secondHandLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
    self.startHandLayer.transform  = CATransform3DMakeRotation(0, 0, 0, 1);
    self.nowHandLayer.transform    = CATransform3DMakeRotation(0, 0, 0, 1);

    for (NSUInteger i = 0; i < self.secondHandProgressTicksLayer.sublayers.count; i++) {
        NoHitCAShapeLayer *layer = [self.secondHandProgressTicksLayer.sublayers objectAtIndex:i];
        layer.hidden = NO;
    }
}

#pragma mark -
#pragma mark Private methods

- (void)prepareForReuse {
    self.previousSecondTick = -1;
    self.previousNow        = -1;

    [self.updateTimer invalidate];
}

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
	self.startHandLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
}

- (void)drawNow {
	NSTimeInterval timeInterval    = [self.nowDate timeIntervalSinceDate:self.startDate];
	CGFloat elapsedSecondsIntoHour = (CGFloat)fmod(timeInterval, 3600);

	// We want fluid updates to the seconds
	CGFloat a = (CGFloat)((M_PI * 2) * fmod(elapsedSecondsIntoHour, 60) / 60);
	self.secondHandLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);

	// Update the tick marks for the second hand
	CGFloat secondTick = (CGFloat)floor(fmod(elapsedSecondsIntoHour, 60));

    if (secondTick != self.previousSecondTick) {
        for (NSUInteger i = 0; i < self.secondHandProgressTicksLayer.sublayers.count; i++) {
            NoHitCAShapeLayer *layer = [self.secondHandProgressTicksLayer.sublayers objectAtIndex:i];

            if (i < secondTick) {
                layer.hidden = NO;
            } else {
                layer.hidden = YES;
            }
        }

        self.previousSecondTick = secondTick;
    }

	// And for the minutes we want a more tick/tock behavior
	a = (CGFloat)((M_PI * 2) * floor(elapsedSecondsIntoHour / 60) / 60);
    if (a != self.previousNow) {
        self.nowHandLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);
        self.previousNow = a;
    }
}

- (void)drawClockFace {
	CGFloat angle;

    self.layer.contentsScale = [UIScreen mainScreen].scale;

    // =====================
    // = Ticks initializer =
    // =====================
    UIBezierPath *largeTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 5.0, 14)];
    UIBezierPath *smallTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 11.0)];

	for (NSInteger i = 1; i <= 60; ++i) {
		NoHitCAShapeLayer *tick = [NoHitCAShapeLayer layer];
        tick.contentsScale = [UIScreen mainScreen].scale;

		angle = (CGFloat)((M_PI * 2) / 60.0 * i);

		if (i % 10 == 0) {
            // position
			tick.bounds      = CGRectMake(0.0, 0.0, 5.0, self.bounds.size.width / 2 - 30);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.anchorPoint = CGPointMake(0.5, 1.0);

            // drawing
			tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
			tick.fillColor   = [[UIColor whiteColor] CGColor];
			tick.lineWidth   = 1;
			tick.path        = largeTickPath.CGPath;
		} else {
            // position
			tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.width / 2.0 - 31.5);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.anchorPoint = CGPointMake(0.5, 1.0);

            // drawing
			tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
			tick.fillColor   = [[UIColor colorWithWhite:0.651 alpha:1.000] CGColor];
			tick.lineWidth   = 1;
			tick.path        = smallTickPath.CGPath;
		}

		[self.layer addSublayer:tick];
	}

    // ==========================
    // = Minutehand initializer =
    // ==========================
	self.nowHandLayer = [CAShapeLayer layer];
    self.nowHandLayer.contentsScale = [UIScreen mainScreen].scale;

    // We make the bounds larger for the hit test, otherwise the target is
    // to damn small for human hands, martians not included
    UIBezierPath *nowHandPath = [UIBezierPath bezierPath];
    [nowHandPath moveToPoint:CGPointMake(10, 17)];   // Start at the top
    [nowHandPath addLineToPoint:CGPointMake(5, 0)];  // Move to bottom left
    [nowHandPath addLineToPoint:CGPointMake(15, 0)]; // Move to bottom right

    // position
	self.nowHandLayer.bounds      = CGRectMake(0.0, 0.0, 20, 19);
	self.nowHandLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.nowHandLayer.anchorPoint = CGPointMake(0.5, 8.05);

    // drawing
	self.nowHandLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
	self.nowHandLayer.fillColor   = [[UIColor colorWithRed:0.098 green:0.800 blue:0.000 alpha:1.000] CGColor];
	self.nowHandLayer.lineWidth   = 1.0;
	self.nowHandLayer.path        = nowHandPath.CGPath;

	[self.layer addSublayer:self.nowHandLayer];

    // =========================
    // = Starthand initializer =
    // =========================
	self.startHandLayer = [CAShapeLayer layer];
    self.startHandLayer.contentsScale = [UIScreen mainScreen].scale;

    // We make the bounds larger for the hit test, otherwise the target is
    // to damn small for human hands, martians not included
    UIBezierPath *startHandPath = [UIBezierPath bezierPath];
    [startHandPath moveToPoint:CGPointMake(10, 0)];     // Start at the top
    [startHandPath addLineToPoint:CGPointMake(5, 17)];  // Move to bottom left
    [startHandPath addLineToPoint:CGPointMake(15, 17)]; // Move to bottom right

    // position
    self.startHandLayer.bounds      = CGRectMake(0.0, 0.0, 20, 19);
	self.startHandLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.startHandLayer.anchorPoint = CGPointMake(0.5, 5.8);

    // drawing
	self.startHandLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
	self.startHandLayer.fillColor   = [[UIColor colorWithRed:1.000 green:0.600 blue:0.008 alpha:1.000] CGColor];
	self.startHandLayer.lineWidth   = 1.0;
	self.startHandLayer.path        = startHandPath.CGPath;

	[self.layer addSublayer:self.startHandLayer];

    // ==========================
    // = Secondhand initializer =
    // ==========================
	self.secondHandLayer = [NoHitCAShapeLayer layer];
    self.secondHandLayer.contentsScale = [UIScreen mainScreen].scale;

    UIBezierPath *secondHandPath = [UIBezierPath bezierPath];
    [secondHandPath moveToPoint:CGPointMake(3.5, 0)];  // Start at the top
    [secondHandPath addLineToPoint:CGPointMake(0, 7)]; // Move to bottom left
    [secondHandPath addLineToPoint:CGPointMake(7, 7)]; // Move to bottom right

    // position
	self.secondHandLayer.bounds      = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.width / 2.0 - 62);
	self.secondHandLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHandLayer.anchorPoint = CGPointMake(0.5, 1.0);

    // drawing
	self.secondHandLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
	self.secondHandLayer.fillColor   = [[UIColor redColor] CGColor];
	self.secondHandLayer.lineWidth   = 1.0;
	self.secondHandLayer.path        = secondHandPath.CGPath;

	[self.layer addSublayer:self.secondHandLayer];

    // =========================================
    // = Secondhand progress ticks initializer =
    // =========================================
	self.secondHandProgressTicksLayer             = [NoHitCAShapeLayer layer];
    self.secondHandProgressTicksLayer.contentsScale = [UIScreen mainScreen].scale;

    // position
	self.secondHandProgressTicksLayer.bounds      = CGRectMake(0.0, 0.0, self.bounds.size.width - 100, self.bounds.size.width - 100);
	self.secondHandProgressTicksLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHandProgressTicksLayer.anchorPoint = CGPointMake(0.5, 0.5);

	[self.layer addSublayer:self.secondHandProgressTicksLayer];

    UIBezierPath *secondHandTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 2.0)];
	for (NSInteger i = 1; i <= 60; ++i) {
		angle = (CGFloat)((M_PI * 2) / 60.0 * i);

		NoHitCAShapeLayer *tick = [NoHitCAShapeLayer layer];
        tick.contentsScale = [UIScreen mainScreen].scale;

        // position
		tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.secondHandProgressTicksLayer.bounds.size.width / 2);
		tick.position    = CGPointMake(CGRectGetMidX(self.secondHandProgressTicksLayer.bounds), CGRectGetMidY(self.secondHandProgressTicksLayer.bounds));
		tick.anchorPoint = CGPointMake(0.5, 1.0);

        // drawing
		tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
		tick.fillColor   = [[UIColor redColor] CGColor];
		tick.lineWidth   = 1;
		tick.path        = secondHandTickPath.CGPath;

		[self.secondHandProgressTicksLayer addSublayer:tick];
	}
}

#pragma mark -
#pragma mark UIControl

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a;

	self.deltaLayer = nil;

	if ([self.startHandLayer.presentationLayer hitTest:point]) {
		self.deltaLayer = self.startHandLayer;
		self.deltaDate  = self.startDate;

        self.isTransforming = EventTimerTransformingStartDateStart;

        [self.updateTimer invalidate];
	} else if ([self.nowHandLayer.presentationLayer hitTest:point] && ![self.event isActive]) {
		self.deltaLayer = self.nowHandLayer;
		self.deltaDate  = self.nowDate;

        self.isTransforming = EventTimerTransformingStopDateStart;
    }

	if (self.deltaLayer != nil) {
		// Calculate the angle in radians
		cx = self.deltaLayer.position.x;
		cy = self.deltaLayer.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a  = (CGFloat)atan2(dy,dx);

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

		// If we are tracking the start hand then
		// we cant move past the now
		if (self.deltaLayer == self.startHandLayer) {
			CGFloat seconds = (CGFloat)[self angleToTimeInterval:da];

			NSDate *startDate = [self.deltaDate dateByAddingTimeInterval:seconds];
			self.deltaDate    = startDate;

            if ([[startDate laterDate:self.nowDate] isEqualToDate:startDate]) {
				startDate = self.nowDate;
				transform = self.nowHandLayer.transform;
			}

			self.startDate = startDate;
		} else if (self.deltaLayer == self.nowHandLayer) {
			CGFloat seconds = (CGFloat)[self angleToTimeInterval:da];

			NSDate *nowDate = [self.deltaDate dateByAddingTimeInterval:seconds];
			self.deltaDate  = nowDate;

			if ([[nowDate earlierDate:self.startDate] isEqualToDate:nowDate]) {
				nowDate   = self.startDate;
				transform = self.startHandLayer.transform;
			}

            self.nowDate  = nowDate;
            self.stopDate = nowDate;
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
		// If we are tracking the start hand then
		// we want to move the startHand to it's start position
		if (self.deltaLayer == self.startHandLayer) {
            [self drawStart];
            [self drawNow];

            self.isTransforming = EventTimerTransformingStartDateStop;

            // Resume the passing of time
            if (![self.updateTimer isValid] && [self.event isActive]) {
                self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                                    target:self
                                                                  selector:@selector(timerUpdate)
                                                                  userInfo:nil
                                                                   repeats:YES];
            }            
		} else if (self.deltaLayer == self.nowHandLayer) {
            self.isTransforming = EventTimerTransformingStopDateStop;
        }

		self.deltaLayer = nil;
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end