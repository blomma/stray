//
//  TimerFaceControl.m
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerFaceControl.h"

static CGFloat calculateDifferenceBetweenAngles(CGFloat a, CGFloat b) {
	CGFloat difference = b - a;

	while (difference < -M_PI) {
		difference += 2 * M_PI;
	}
	while (difference > M_PI) {
		difference -= 2 * M_PI;
	}

	return difference;
}

static NSTimeInterval angleToSeconds(CGFloat angle) {
	CGFloat hours = angle / (2 * M_PI);
	return hours * 3600;
}

@interface TimerFaceControl ()

// Redefine public properties
@property (nonatomic, readwrite) NSDate *startDate;
@property (nonatomic, readwrite) NSDate *nowDate;
@property (nonatomic, readwrite) NSDate *stopDate;

// Private properties
@property (nonatomic) NSTimer *updateTimer;
@property (nonatomic) BOOL isTimerRunning;

@property (nonatomic) CAShapeLayer *startHandLayer;
@property (nonatomic) CAShapeLayer *minuteHandLayer;
@property (nonatomic) CAShapeLayer *secondHandLayer;
@property (nonatomic) CAShapeLayer *secondHandProgressTicksLayer;

// Touch transforming
@property (nonatomic) NSDate *deltaDate;
@property (nonatomic) CGFloat startAngle;
@property (nonatomic) CGFloat deltaAngle;
@property (nonatomic) CATransform3D startTransform;
@property (nonatomic) CATransform3D deltaTransform;
@property (nonatomic) CAShapeLayer *layerTransforming;

@end

@implementation TimerFaceControl

#pragma mark -
#pragma mark Public properties



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
	if (self.isTimerRunning) {
		if (![self.updateTimer isValid]) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
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

- (void)startWithDate:(NSDate *)date {
	self.startDate = date;

	self.isTimerRunning = YES;

	// Scehdule a timer to update the face
	if (![self.updateTimer isValid]) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
		                                                    target:self
		                                                  selector:@selector(timerUpdate)
		                                                  userInfo:nil
		                                                   repeats:YES];
	}

	[self drawStart];
}

- (void)stopWithDate:(NSDate *)date {
	[self.updateTimer invalidate];

	self.isTimerRunning = NO;

	// Sync stop and now
	self.nowDate  = date;
	self.stopDate = date;

	[self drawNow];
}

#pragma mark -
#pragma mark Private instance methods

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
	CGFloat elapsedSecondsIntoHour = fmod(timeInterval, 3600);

	// We want fluid updates to the seconds
	CGFloat a = (M_PI * 2) * fmod(elapsedSecondsIntoHour, 60) / 60.0;
	self.secondHandLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);

	// Update the tick marks for the second hand
	int secondsIntoMinute = floor(fmod(elapsedSecondsIntoHour, 60));

	for (int i = 0; i < self.secondHandProgressTicksLayer.sublayers.count; i++) {
		CALayer *layer = [self.secondHandProgressTicksLayer.sublayers objectAtIndex:i];

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
	a                              = (M_PI * 2) * floor(elapsedSecondsIntoHour / 60) / 60;
	self.minuteHandLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);
}

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
	self.minuteHandLayer = [CAShapeLayer layer];

	path                 = CGPathCreateMutable();

	// start at top
	CGPathMoveToPoint(path, NULL, 5.0, 17.0);
	// move to bottom left
	CGPathAddLineToPoint(path, NULL, 0.0, 0.0);
	// move to bottom right
	CGPathAddLineToPoint(path, NULL, 9.0, 0.0);
	CGPathCloseSubpath(path);

	self.minuteHandLayer.fillColor   = [[UIColor colorWithRed:0.098 green:0.800 blue:0.000 alpha:1.000] CGColor];
	self.minuteHandLayer.lineWidth   = 1.0;

	self.minuteHandLayer.bounds      = CGRectMake(0.0, 0.0, 9.0, self.bounds.size.height / 2.0 - 12);
	self.minuteHandLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.minuteHandLayer.anchorPoint = CGPointMake(0.5, 1.0);
	self.minuteHandLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
	self.minuteHandLayer.path        = path;

	[self.layer addSublayer:self.minuteHandLayer];

	// start hand
	self.startHandLayer = [CAShapeLayer layer];

	path                = CGPathCreateMutable();

	// start at top
	CGPathMoveToPoint(path, NULL, 5, 0.0);
	// move to bottom left
	CGPathAddLineToPoint(path, NULL, 0.0, 17.0);
	// move to bottom right
	CGPathAddLineToPoint(path, NULL, 9.0, 17.0);
	CGPathCloseSubpath(path);

	self.startHandLayer.fillColor   = [[UIColor colorWithRed:1.000 green:0.600 blue:0.008 alpha:1.000] CGColor];
	self.startHandLayer.lineWidth   = 1.0;

	self.startHandLayer.bounds      = CGRectMake(0.0, 0.0, 9.0, self.bounds.size.height / 2 - 50);
	self.startHandLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.startHandLayer.anchorPoint = CGPointMake(0.5, 1.0);
	self.startHandLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
	self.startHandLayer.path        = path;

	[self.layer addSublayer:self.startHandLayer];

	// second hand
	self.secondHandLayer = [CAShapeLayer layer];

	path                 = CGPathCreateMutable();

	// start at top
	CGPathMoveToPoint(path, NULL, 3.5, 0.0);
	// move to bottom left
	CGPathAddLineToPoint(path, NULL, 0.0, 7.0);
	// move to bottom right
	CGPathAddLineToPoint(path, NULL, 7.0, 7.0);
	CGPathCloseSubpath(path);

	self.secondHandLayer.fillColor   = [[UIColor redColor] CGColor];
	self.secondHandLayer.lineWidth   = 1.0;

	self.secondHandLayer.bounds      = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.height / 2.0 - 62);
	self.secondHandLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHandLayer.anchorPoint = CGPointMake(0.5, 1.0);
	self.secondHandLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);
	self.secondHandLayer.path        = path;

	[self.layer addSublayer:self.secondHandLayer];

	// second hand progress ticks
	self.secondHandProgressTicksLayer             = [CAShapeLayer layer];
	self.secondHandProgressTicksLayer.bounds      = CGRectMake(0.0, 0.0, self.bounds.size.width - 100, self.bounds.size.height - 100);
	self.secondHandProgressTicksLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	self.secondHandProgressTicksLayer.anchorPoint = CGPointMake(0.5, 0.5);
	[self.layer addSublayer:self.secondHandProgressTicksLayer];

	// paint the second hand tick marks
	for (NSInteger i = 1; i <= 60; ++i) {
		angle = (M_PI * 2) / 60.0 * i;

		CAShapeLayer *tick = [CAShapeLayer layer];
		path = CGPathCreateMutable();

		CGPathAddRect(path, nil, CGRectMake(0.0, 0.0, 3.0, 2.0));

		tick.fillColor   = [[UIColor redColor] CGColor];
		tick.lineWidth   = 1;

		tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.secondHandProgressTicksLayer.bounds.size.height / 2);
		tick.anchorPoint = CGPointMake(0.5, 1.0);
		tick.position    = CGPointMake(CGRectGetMidX(self.secondHandProgressTicksLayer.bounds), CGRectGetMidY(self.secondHandProgressTicksLayer.bounds));
		tick.transform   = CATransform3DMakeRotation(angle, 0, 0, 1);
		tick.path        = path;

		[self.secondHandProgressTicksLayer addSublayer:tick];
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

	self.layerTransforming = NULL;

	// Was this a touch on the startHand and is the timer started
	if ([self.startHandLayer.presentationLayer hitTest:point] && self.isTimerRunning) {
		self.layerTransforming = self.startHandLayer;
	}

	if (self.layerTransforming != NULL) {
		// Calculate the angle in radians
		cx = self.layerTransforming.position.x;
		cy = self.layerTransforming.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a  = atan2(dy,dx);

		// Save them for later use
		if (self.startHandLayer == self.layerTransforming) {
			self.deltaDate = self.startDate;
		}

		self.startAngle     = a;
		self.deltaAngle     = 0;

		self.startTransform = self.layerTransforming.transform;
		self.deltaTransform = self.layerTransforming.transform;

		// Temporarily disable the passing of time
		[self.updateTimer invalidate];
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return self.layerTransforming != NULL;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a, da;

	if (self.layerTransforming != NULL) {
		// Calculate the angle in radians
		cx = self.layerTransforming.position.x;
		cy = self.layerTransforming.position.y;

		dx = point.x - cx;
		dy = point.y - cy;

		a  = atan2(dy, dx);
		da = self.startAngle - a;

		// The transform before we apply the new transform
		CATransform3D t              = self.deltaTransform;
		CGFloat angleBeforeTransform = atan2(t.m12, t.m11);

		// The new transform applied
		t = CATransform3DRotate(self.startTransform, -da, 0, 0, 1);
		CGFloat angleAfterTransform = atan2(t.m12, t.m11);

		CGFloat angleDifference     = calculateDifferenceBetweenAngles(angleBeforeTransform, angleAfterTransform);

		self.deltaAngle += angleDifference;
		DLog(@"deltaAngle:%f", self.deltaAngle);

		self.deltaTransform = t;

		// If we are tracking the start hand then
		// we cant move past the now
		if (self.layerTransforming == self.startHandLayer) {
			CGFloat seconds = angleToSeconds(self.deltaAngle);
			DLog(@"seconds:%f", seconds);

			NSDate *startHandDate = [self.deltaDate dateByAddingTimeInterval:seconds];
//			self.deltaDate = startHandDate;

			// A negative time diff is past the now, if so we set
			// startDate to the now
			NSTimeInterval timeDiff = [self.nowDate timeIntervalSinceDate:startHandDate];
			if (timeDiff < 0) {
				startHandDate = self.nowDate;
				t             = self.minuteHandLayer.transform;
			}

			self.startDate = startHandDate;

			[CATransaction begin];
			[CATransaction setDisableActions:YES];

			self.layerTransforming.transform = t;

			[CATransaction commit];
		}
	}

	[self sendActionsForControlEvents:UIControlEventValueChanged];

	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint point = [touch locationInView:self];

	DLog(@"endTrackingWithTouch");

	// We need to snap the startHand to the closest minute
	[self sendActionsForControlEvents:UIControlEventValueChanged];

	// Resume the passing of time
	if (![self.updateTimer isValid]) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
		                                                    target:self
		                                                  selector:@selector(timerUpdate)
		                                                  userInfo:nil
		                                                   repeats:YES];
	}

	// Do a initial fire of the event to get things started
	[self.updateTimer fire];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
	// Resume the passing of time
	if (![self.updateTimer isValid]) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
		                                                    target:self
		                                                  selector:@selector(timerUpdate)
		                                                  userInfo:nil
		                                                   repeats:YES];
	}

	// Do a initial fire of the event to get things started
	[self.updateTimer fire];
}

#pragma mark -
#pragma mark UIView

@end
