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

// Private properties
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) BOOL isEventActive;

@property (nonatomic) CAShapeLayer *startHandLayer;
@property (nonatomic) CAShapeLayer *nowHandLayer;
@property (nonatomic) NoHitCAShapeLayer *secondHandLayer;
@property (nonatomic) NoHitCAShapeLayer *secondHandProgressTicksLayer;

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
#pragma mark Public properties

- (void)setStartDate:(NSDate *)startDate {
	_startDate = startDate;

	if (self.deltaLayer == NULL) {
		[self drawStart];
	}
}

- (void)setNowDate:(NSDate *)nowDate {
	_nowDate = nowDate;

	if (self.deltaLayer == NULL) {
		[self drawNow];
	}
}

#pragma mark -
#pragma mark Application lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
        [self setUpClock];
	}

	return self;
}

- (void)viewDidDisappear:(BOOL)animated {
	if ([self.updateTimer isValid]) {
		[self.updateTimer invalidate];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	if (self.isEventActive) {
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

#pragma mark -
#pragma mark Public instance methods

- (void)startWithDate:(NSDate *)date  {
	self.startDate = date;
	[self drawStart];

	self.isEventActive = YES;

	// Scehdule a timer to update the face
	if (![self.updateTimer isValid]) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
		                                                    target:self
		                                                  selector:@selector(timerUpdate)
		                                                  userInfo:nil
		                                                   repeats:YES];
	}

	[self.updateTimer fire];
}

- (void)stopWithDate:(NSDate *)date {
	[self.updateTimer invalidate];

	self.isEventActive = NO;

	// Sync stop and now
	self.nowDate  = date;
	self.stopDate = date;

	[self drawNow];
}

#pragma mark -
#pragma mark Private instance methods

- (NSTimeInterval)angleToTimeInterval:(CGFloat)a {
	CGFloat seconds = (CGFloat)((a / (2 * M_PI)) * 3600);
	return seconds;
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
	if ([self.updateTimer isValid]) {
		self.nowDate = [NSDate date];

		[self drawNow];
	}
}

- (void)drawStart {
	CGFloat a = (M_PI * 2) * 0;
	self.startHandLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);
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
            CALayer *layer = [self.secondHandProgressTicksLayer.sublayers objectAtIndex:i];

            if (i < secondTick) {
                if (layer.hidden) {
                    layer.hidden = NO;
                }
            } else {
                if (!layer.hidden) {
                    layer.hidden = YES;
                }
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

- (void)setUpClock {
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
			tick.fillColor   = [[UIColor whiteColor] CGColor];
			tick.lineWidth   = 1;
			tick.bounds      = CGRectMake(0.0, 0.0, 5.0, self.bounds.size.width / 2 - 30);
			tick.anchorPoint = CGPointMake(0.5, 1.0);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
			tick.path        = largeTickPath.CGPath;
		} else {
			tick.fillColor   = [[UIColor colorWithWhite:0.651 alpha:1.000] CGColor];
			tick.lineWidth   = 1;
			tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.width / 2.0 - 31.5);
			tick.anchorPoint = CGPointMake(0.5, 1.0);
			tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
			tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
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

	self.secondHandLayer.fillColor   = [[UIColor redColor] CGColor];
	self.secondHandLayer.lineWidth   = 1.0;
	self.secondHandLayer.bounds      = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.width / 2.0 - 62);
	self.secondHandLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHandLayer.anchorPoint = CGPointMake(0.5, 1.0);
	self.secondHandLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
	self.secondHandLayer.path        = secondHandPath.CGPath;

	[self.layer addSublayer:self.secondHandLayer];

    // =========================================
    // = Secondhand progress ticks initializer =
    // =========================================
	self.secondHandProgressTicksLayer             = [NoHitCAShapeLayer layer];
    self.secondHandProgressTicksLayer.contentsScale = [UIScreen mainScreen].scale;

	self.secondHandProgressTicksLayer.bounds      = CGRectMake(0.0, 0.0, self.bounds.size.width - 100, self.bounds.size.width - 100);
	self.secondHandProgressTicksLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHandProgressTicksLayer.anchorPoint = CGPointMake(0.5, 0.5);

	[self.layer addSublayer:self.secondHandProgressTicksLayer];

    UIBezierPath *secondHandTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 2.0)];
	for (NSInteger i = 1; i <= 60; ++i) {
		angle = (CGFloat)((M_PI * 2) / 60.0 * i);

		NoHitCAShapeLayer *tick = [NoHitCAShapeLayer layer];
        tick.contentsScale = [UIScreen mainScreen].scale;


		tick.fillColor   = [[UIColor redColor] CGColor];
		tick.lineWidth   = 1;

		tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.secondHandProgressTicksLayer.bounds.size.width / 2);
		tick.anchorPoint = CGPointMake(0.5, 1.0);
		tick.position    = CGPointMake(CGRectGetMidX(self.secondHandProgressTicksLayer.bounds), CGRectGetMidY(self.secondHandProgressTicksLayer.bounds));
		tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
		tick.path        = secondHandTickPath.CGPath;

		[self.secondHandProgressTicksLayer addSublayer:tick];
	}
}

#pragma mark -
#pragma mark UIControl

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a;

	self.deltaLayer = NULL;

	if ([self.startHandLayer.presentationLayer hitTest:point]) {
		self.deltaLayer = self.startHandLayer;
		self.deltaDate  = self.startDate;
        self.isTransforming = EventTimerTransformingStartHandStart;
	} else if ([self.nowHandLayer.presentationLayer hitTest:point] && !self.isEventActive) {
		self.deltaLayer = self.nowHandLayer;
		self.deltaDate  = self.stopDate;
        self.isTransforming = EventTimerTransformingStopHandStart;
    }

	if (self.deltaLayer != NULL) {
		// Calculate the angle in radians
		cx = self.deltaLayer.position.x;
		cy = self.deltaLayer.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a  = (CGFloat)atan2(dy,dx);

		// Save them away for future iteration
		self.deltaAngle     = a;
		self.deltaTransform = self.deltaLayer.transform;

		// Temporarily disable the passing of time
        if (self.updateTimer.isValid) {
            [self.updateTimer invalidate];
        }
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return self.deltaLayer != NULL;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a, da;

	if (self.deltaLayer != NULL) {
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
			CGFloat seconds       = (CGFloat)[self angleToTimeInterval:da];

			NSDate *startHandDate = [self.deltaDate dateByAddingTimeInterval:seconds];
			self.deltaDate = startHandDate;

			// A negative time diff is past the now, if so we set
			// startDate to the now
			NSTimeInterval timeDiff = [self.nowDate timeIntervalSinceDate:startHandDate];
			if (timeDiff < 0) {
				startHandDate = self.nowDate;
				transform     = self.nowHandLayer.transform;
			}

			self.startDate = startHandDate;
		} else if (self.deltaLayer == self.nowHandLayer) {
			CGFloat seconds       = (CGFloat)[self angleToTimeInterval:da];

			NSDate *stopHandDate = [self.deltaDate dateByAddingTimeInterval:seconds];
			self.deltaDate = stopHandDate;

			// A negative time diff is past the start, if so we set
			// startDate to the now
			NSTimeInterval timeDiff = [self.startDate timeIntervalSinceDate:stopHandDate];
			if (timeDiff > 0) {
				stopHandDate = self.startDate;
				transform     = self.startHandLayer.transform;
			}

			self.nowDate = stopHandDate;
            self.stopDate = stopHandDate;
        }

        [CATransaction begin];
        [CATransaction setDisableActions:YES];

        self.deltaLayer.transform = transform;

        [CATransaction commit];
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return self.deltaLayer != NULL;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	if (self.deltaLayer != NULL) {
		// If we are tracking the start hand then
		// we want to move the startHand to it's start position
		if (self.deltaLayer == self.startHandLayer) {
			self.deltaLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);

			// Lets persist this new fangled startDate
			Event *currentEvent = [[EventDataManager sharedManager] currentEvent];
			currentEvent.startDate = self.startDate;

            self.isTransforming = EventTimerTransformingStartHandStop;

			[[EventDataManager sharedManager] persistCurrentEvent];

            // Resume the passing of time
            if (![self.updateTimer isValid]) {
                self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                                    target:self
                                                                  selector:@selector(timerUpdate)
                                                                  userInfo:nil
                                                                   repeats:YES];
            }
            
            // Do a initial fire of the event to get things started
            [self.updateTimer fire];
		} else if (self.deltaLayer == self.nowHandLayer) {
			// Lets persist this new fangled startDate
			Event *currentEvent = [[EventDataManager sharedManager] currentEvent];
			currentEvent.stopDate = self.stopDate;

            self.isTransforming = EventTimerTransformingStartHandStop;

			[[EventDataManager sharedManager] persistCurrentEvent];
        }

		self.deltaLayer = NULL;
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end