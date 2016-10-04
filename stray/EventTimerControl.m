#define DLog(...) NSLog(@"FUNC %s[%d][%@]->%@", __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], [NSString stringWithFormat:__VA_ARGS__])

#import "EventTimerControl.h"

@interface EventTimerControl ()

@property (nonatomic) NSTimer      *updateTimer;
@property (nonatomic) BOOL isStopped;
@property (nonatomic) BOOL isStarted;

@property (nonatomic) CAShapeLayer *startTouchPathLayer;
@property (nonatomic) CAShapeLayer *startLayer;
@property (nonatomic) CAShapeLayer *startPathLayer;

@property (nonatomic) CAShapeLayer *stopTouchPathLayer;
@property (nonatomic) CAShapeLayer *stopLayer;
@property (nonatomic) CAShapeLayer *stopPathLayer;

@property (nonatomic) CAShapeLayer *secondLayer;
@property (nonatomic) CAShapeLayer *secondProgressTicksLayer;

// Touch transforming
@property (nonatomic) CGFloat       deltaAngle;
@property (nonatomic) CATransform3D deltaTransform;
@property (nonatomic) CAShapeLayer  *deltaLayer;

@property (nonatomic) BOOL tracking;
@property (nonatomic) NSUInteger trackingTouch;

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *runningDate;
@property (nonatomic) NSDate *stopDate;
@property (nonatomic) EventTimerTransformingEnum transforming;

@end

@implementation EventTimerControl

- (void)drawRect:(CGRect)rect {
	[self drawClockFace];
}

- (void)dealloc {
	[self.updateTimer invalidate];
}

#pragma mark -
#pragma mark Public properties

- (void)setStartDate:(NSDate *)startDate {
	_startDate = startDate;

	if([self.delegate respondsToSelector:@selector(startDateDidUpdate:)]) {
		[self.delegate startDateDidUpdate:startDate];
	}
}

- (void)setRunningDate:(NSDate *)runningDate {
	_runningDate = runningDate;

	if([self.delegate respondsToSelector:@selector(runningDateDidUpdateFrom:to:)]) {
		[self.delegate runningDateDidUpdateFrom:self.startDate to:runningDate];
	}
}

- (void)setStopDate:(NSDate *)stopDate {
	_stopDate = stopDate;

	if([self.delegate respondsToSelector:@selector(stopDateDidUpdate:)]) {
		[self.delegate stopDateDidUpdate:stopDate];
	}
}

- (void)setTransforming:(EventTimerTransformingEnum)transforming {
	_transforming = transforming;

	if([self.delegate respondsToSelector:@selector(transformingDidUpdate:with:)]) {
		switch (transforming) {
			case EventTimerStartDateDidChange:
				[self.delegate transformingDidUpdate:transforming with:self.startDate];
				break;
			case EventTimerStopDateDidChange:
				[self.delegate transformingDidUpdate:transforming with:self.stopDate];
				break;
		}
	}
}

#pragma mark -
#pragma mark Public methods

- (void)initWithStartDate:(NSDate *)startDate andStopDate:(NSDate *)stopDate {
	[self reset];

	self.startDate = startDate;
	[self drawStart:self.startDate];

	self.isStarted = YES;
	self.isStopped = stopDate != nil ? YES : NO;

	self.runningDate = self.isStopped ? stopDate : [NSDate date];
	self.stopDate = stopDate;

	[self drawStop:self.isStopped ? self.stopDate : self.runningDate];

	if (!self.isStopped) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
															target:self
														  selector:@selector(timerUpdate)
														  userInfo:nil
														   repeats:YES];
	}
}

- (void)stop {
	[self.updateTimer invalidate];

	self.isStopped = YES;
	self.stopDate = [NSDate date];
}

- (void)reset {
	[self.updateTimer invalidate];

	self.isStarted = NO;
	self.isStopped = NO;

	self.secondLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
	self.startLayer.transform  = CATransform3DMakeRotation(0, 0, 0, 1);
	self.stopLayer.transform    = CATransform3DMakeRotation(0, 0, 0, 1);

	self.startTouchPathLayer.strokeEnd = 0;
	self.stopTouchPathLayer.strokeEnd   = 0;

	for (NSUInteger i = 0; i < self.secondProgressTicksLayer.sublayers.count; i++) {
		CALayer *layer = [self.secondProgressTicksLayer.sublayers objectAtIndex:i];
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
	self.runningDate = [NSDate date];

	[self drawStop:self.runningDate];
}

- (void)drawStart:(NSDate *)startDate {
	NSTimeInterval startSeconds = [startDate timeIntervalSince1970];

	CGFloat a = (CGFloat)((M_PI * 2) * floor(fmod(startSeconds, 3600) / 60) / 60);
	self.startLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);
}

- (void)drawStop:(NSDate *)stopDate {
	NSTimeInterval stopSeconds = [stopDate timeIntervalSince1970];

	// We want fluid updates to the seconds
	double secondsIntoMinute = fmod(stopSeconds, 60);

	CGFloat a = (CGFloat)(M_PI * 2 * (secondsIntoMinute / 60));

	self.secondLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);

	// Update the tick marks for the seconds
	CGFloat secondTick = (CGFloat)floor(secondsIntoMinute);
	for (NSUInteger i = 0; i < self.secondProgressTicksLayer.sublayers.count; i++) {
		CALayer *layer = [self.secondProgressTicksLayer.sublayers objectAtIndex:i];

		if (i < secondTick) {
			layer.hidden = NO;
		} else {
			layer.hidden = YES;
		}
	}

	double secondsIntoHour = fmod(stopSeconds, 3600);

	// And for the minutes we want a more tick/tock behavior
	a = (CGFloat)(M_PI * 2 * (floor(secondsIntoHour / 60) / 60));
	self.stopLayer.transform = CATransform3DMakeRotation(a, 0, 0, 1);
}

- (void)drawClockFace {
    CGFloat angle;

    // =====================
    // = Ticks initializer =
    // =====================
    UIBezierPath *largeTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 5.0, 14)];
    UIBezierPath *smallTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 11.0)];

    for (NSInteger i = 1; i <= 60; ++i) {
        CAShapeLayer *tick = [CAShapeLayer layer];

        angle = (CGFloat)((M_PI * 2) / 60.0 * i);

        if (i % 15 == 0) {
            // position
            tick.bounds      = CGRectMake(0.0, 0.0, 5.0, self.bounds.size.width / 2 - 30);
            tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
            tick.anchorPoint = CGPointMake(0.5, 1.0);

            // drawing
            tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
            tick.fillColor = [[UIColor colorWithWhite:0.167f alpha:1] CGColor];
            tick.lineWidth = 1;
            tick.path      = largeTickPath.CGPath;
        } else {
            // position
            tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.bounds.size.width / 2.0f - 31.5f);
            tick.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
            tick.anchorPoint = CGPointMake(0.5, 1.0);

            // drawing
            tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
            tick.fillColor = [[UIColor colorWithWhite:0.292f alpha:1] CGColor];
            tick.lineWidth = 1;
            tick.path      = smallTickPath.CGPath;
        }

        [self.layer addSublayer:tick];
    }

    // ==========================
    // = Stop initializer =
    // ==========================
    self.stopLayer = [CAShapeLayer layer];

    // We make the bounds larger for the hit test, otherwise the target is
    // to damn small for human hands, martians not included
    UIBezierPath *stopPath = [UIBezierPath bezierPath];
    [stopPath moveToPoint:CGPointMake(25, 17)];   // Start at the bottom
    [stopPath addLineToPoint:CGPointMake(20, 0)];  // Move to top left
    [stopPath addLineToPoint:CGPointMake(30, 0)]; // Move to top right

    self.stopPathLayer = [CAShapeLayer layer];
    self.stopPathLayer.frame = CGRectMake(0, 0, 50, 50);

    // drawing
    self.stopPathLayer.fillColor = [[UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1] CGColor];
    self.stopPathLayer.lineWidth = 1.0;
    self.stopPathLayer.path      = stopPath.CGPath;

    // touch path
    UIBezierPath *stopTouchPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-50, -50, 150, 150)];

    self.stopTouchPathLayer = [CAShapeLayer layer];
    self.stopTouchPathLayer.frame = CGRectMake(-10, -30, 70, 70);

    self.stopTouchPathLayer.fillColor   = [[UIColor clearColor] CGColor];
    self.stopTouchPathLayer.strokeColor = [[UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:0.5f] CGColor];
    self.stopTouchPathLayer.strokeEnd   = 0.0;
    self.stopTouchPathLayer.lineWidth   = 6.0;
    self.stopTouchPathLayer.path        = stopTouchPath.CGPath;

    // position
    self.stopLayer.bounds      = CGRectMake(0.0, 0.0, 50, self.bounds.size.width / 2.0f - 10);
    self.stopLayer.anchorPoint = CGPointMake(0.5, 1.0);
    self.stopLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.stopLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);

    [self.stopLayer addSublayer:self.stopPathLayer];
    [self.stopLayer addSublayer:self.stopTouchPathLayer];
    [self.layer addSublayer:self.stopLayer];

    // =========================
    // = Start initializer =
    // =========================
    self.startLayer = [CAShapeLayer layer];

    // We make the bounds larger for the hit test, otherwise the target is
    // to damn small for human hands, martians not included
    UIBezierPath *startPath = [UIBezierPath bezierPath];
    [startPath moveToPoint:CGPointMake(25, 17)];   // Start at the bottom
    [startPath addLineToPoint:CGPointMake(20, 0)];  // Move to top left
    [startPath addLineToPoint:CGPointMake(30, 0)]; // Move to top right

    self.startPathLayer = [CAShapeLayer layer];
    self.startPathLayer.frame = CGRectMake(0, 0, 50, 50);

    // drawing
    self.startPathLayer.fillColor = [[UIColor colorWithRed:0.941f green:0.686f blue:0.314f alpha:1] CGColor];
    self.startPathLayer.lineWidth = 1.0;
    self.startPathLayer.path      = startPath.CGPath;

    // touch path
    UIBezierPath *startTouchPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-50, -50, 150, 150)];

    self.startTouchPathLayer = [CAShapeLayer layer];
    self.startTouchPathLayer.frame = CGRectMake(-10, -30, 70, 70);

    self.startTouchPathLayer.fillColor   = [[UIColor clearColor] CGColor];
    self.startTouchPathLayer.strokeColor = [[UIColor colorWithRed:0.941f green:0.686f blue:0.314f alpha:0.5f] CGColor];
    self.startTouchPathLayer.strokeEnd   = 0.0;
    self.startTouchPathLayer.lineWidth   = 6.0;
    self.startTouchPathLayer.path        = startTouchPath.CGPath;

    // position
    self.startLayer.bounds      = CGRectMake(0.0, 0.0, 50, self.bounds.size.width / 2.0f - 10);
    self.startLayer.anchorPoint = CGPointMake(0.5, 1.0);
    self.startLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.startLayer.transform   = CATransform3DMakeRotation(0, 0, 0, 1);

    [self.startLayer addSublayer:self.startPathLayer];
    [self.startLayer addSublayer:self.startTouchPathLayer];
    [self.layer addSublayer:self.startLayer];

    // ==========================
    // = Second initializer =
    // ==========================
    self.secondLayer = [CAShapeLayer layer];

    UIBezierPath *secondHandPath = [UIBezierPath bezierPath];
    [secondHandPath moveToPoint:CGPointMake(3.5, 0)];  // Start at the top
    [secondHandPath addLineToPoint:CGPointMake(0, 7)]; // Move to bottom left
    [secondHandPath addLineToPoint:CGPointMake(7, 7)]; // Move to bottom right

    // position
    self.secondLayer.bounds      = CGRectMake(0.0, 0.0, 7.0, self.bounds.size.width / 2.0f - 62);
    self.secondLayer.anchorPoint = CGPointMake(0.5, 1.0);
    self.secondLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    // drawing
    self.secondLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1);
    self.secondLayer.fillColor = [[UIColor colorWithRed:0.843f green:0.306f blue:0.314f alpha:1] CGColor];
    self.secondLayer.lineWidth = 1.0;
    self.secondLayer.path      = secondHandPath.CGPath;

    [self.layer addSublayer:self.secondLayer];

    // =========================================
    // = Second progress ticks initializer =
    // =========================================
    self.secondProgressTicksLayer = [CAShapeLayer layer];

    // position
    self.secondProgressTicksLayer.bounds      = CGRectMake(0.0, 0.0, self.bounds.size.width - 100, self.bounds.size.width - 100);
    self.secondProgressTicksLayer.position    = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.secondProgressTicksLayer.anchorPoint = CGPointMake(0.5, 0.5);

    [self.layer addSublayer:self.secondProgressTicksLayer];

    UIBezierPath *secondHandTickPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0, 0.0, 3.0, 2.0)];
    for (NSInteger i = 1; i <= 60; ++i) {
        angle = (CGFloat)((M_PI * 2) / 60.0 * i);

        CAShapeLayer *tick = [CAShapeLayer layer];

        // position
        tick.bounds      = CGRectMake(0.0, 0.0, 3.0, self.secondProgressTicksLayer.bounds.size.width / 2);
        tick.position    = CGPointMake(CGRectGetMidX(self.secondProgressTicksLayer.bounds), CGRectGetMidY(self.secondProgressTicksLayer.bounds));
        tick.anchorPoint = CGPointMake(0.5, 1.0);

        // drawing
        tick.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
        tick.fillColor = [[UIColor colorWithRed:0.843f green:0.306f blue:0.314f alpha:1] CGColor];
        tick.lineWidth = 1;
        tick.path      = secondHandTickPath.CGPath;

        [self.secondProgressTicksLayer addSublayer:tick];
    }
}

#pragma mark -
#pragma mark UIView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	return !self.tracking;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	// If we have more than one touch then the intent clearly isn't to
	// rotate the dial
	if (touches.count > 1 || !self.isStarted) {
		[super touchesBegan:touches withEvent:event];
	}

	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];

	self.deltaLayer = nil;
	if ([self.startPathLayer.presentationLayer hitTest:[self.startPathLayer convertPoint:point fromLayer:self.layer]]) {
		self.deltaLayer = self.startLayer;

		[self.updateTimer invalidate];
		self.startTouchPathLayer.strokeEnd = 1;
	} else if ([self.stopPathLayer.presentationLayer hitTest:[self.stopPathLayer convertPoint:point fromLayer:self.layer]] && self.isStopped) {
		self.deltaLayer = self.stopLayer;

		self.stopTouchPathLayer.strokeEnd = 1;
	}

	// If the touch hasnt touched either stop or start then forward up
	// the chain and return
	if (self.deltaLayer == nil) {
		[super touchesBegan:touches withEvent:event];
		return;
	}

	CGFloat cx, cy, dx, dy, a;

	// Calculate the angle in radians
	cx = self.deltaLayer.position.x;
	cy = self.deltaLayer.position.y;

	dx = point.x - cx;
	dy = point.y - cy;

	a = (CGFloat)atan2(dy, dx);

	// Save them away for future iteration
	self.deltaAngle     = a;
	self.deltaTransform = self.deltaLayer.transform;

	self.trackingTouch = touch.hash;
	self.tracking = true;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	UITouch *touch = nil;
	for (UITouch *t in touches) {
		if (self.trackingTouch == t.hash) {
			touch = t;
		}
	}

	if (touch == nil || self.deltaLayer == nil) {
		self.tracking = false;
		self.deltaLayer = nil;

		[super touchesMoved:touches withEvent:event];

		return;
	}

	CGPoint point = [touch locationInView:self];

	CGFloat cx, cy, dx, dy, a, da;

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

	if (self.deltaLayer == self.startLayer) {
		CGFloat seconds = (CGFloat)[self angleToTimeInterval : da];

		NSDate *startDate = [self.startDate dateByAddingTimeInterval:seconds];
		self.startDate = startDate;
	} else if (self.deltaLayer == self.stopLayer) {
		CGFloat seconds = (CGFloat)[self angleToTimeInterval : da];

		NSDate *stopDate = [self.stopDate dateByAddingTimeInterval:seconds];
		self.stopDate = stopDate;
	}

	[CATransaction begin];
	[CATransaction setDisableActions:YES];

	self.deltaLayer.transform = transform;

	[CATransaction commit];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	UITouch *touch = nil;
	for (UITouch *t in touches) {
		if (self.trackingTouch == t.hash) {
			touch = t;
		}
	}

	if (touch == nil || self.deltaLayer == nil) {
		self.tracking = false;
		self.deltaLayer = nil;

		[super touchesMoved:touches withEvent:event];

		return;
	}

	if (self.deltaLayer == self.startLayer) {
		[self drawStart:self.startDate];

		self.transforming = EventTimerStartDateDidChange;

		if (![self.updateTimer isValid] && !self.isStopped) {
			self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
																target:self
															  selector:@selector(timerUpdate)
															  userInfo:nil
															   repeats:YES];
		}

		self.startTouchPathLayer.strokeEnd = 0;
	} else if (self.deltaLayer == self.stopLayer) {
		[self drawStop:self.stopDate];

		self.transforming                = EventTimerStopDateDidChange;
		self.stopTouchPathLayer.strokeEnd = 0;
	}

	self.tracking = false;
	self.deltaLayer = nil;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	UITouch *touch = nil;
	for (UITouch *t in touches) {
		if (self.trackingTouch == t.hash) {
			touch = t;
		}
	}

	if (touch == nil || self.deltaLayer == nil) {
		self.tracking = false;
		self.deltaLayer = nil;

		[super touchesMoved:touches withEvent:event];

		return;
	}

	self.tracking = false;
	self.deltaLayer = nil;
}

@end
