#import "NDRotator.h"
#import "Utility.h"

// Contains the radius value of the receiver where 0.0 puts the thumb at the center and 1.0 puts the thumb at margin.
// The values can be greater than 1.0, to reflect user movements outside of the control.
static const CGFloat kRadius = 1.0;

static const CGFloat	kDefaultMinimumValue = 0.0,
						kDefaultMaximumValue = 1.0,
						kDefaultMinimumDomain = 0.0 * M_PI,
						kDefaultMaximumDomain = 2.0 * M_PI;

static NSString	*const kMinimumValueCodingKey = @"minimumValue",
				*const kMaximumValueCodingKey = @"maximumValue",
				*const kMinimumDomainCodingKey = @"minimumDomain",
				*const kMaximumDomainCodingKey = @"maximumDomain";

static void componentsForTint(CGFloat *component, CGFloat value) {
	component[0] = value * (0.55 * 0.5);
	component[1] = value;
	component[2] = value * (0.55);
}

@interface NDRotator ()

@property(strong, nonatomic) UIImage *cachedBodyImage;
@property(strong, nonatomic) UIImage *cachedHilightedBodyImage;
@property(strong, nonatomic) UIImage *cachedThumbImage;
@property(strong, nonatomic) UIImage *cachedHilightedThumbImage;
@property(nonatomic) CGPoint location;

@end

@implementation NDRotator

#pragma mark -
#pragma mark public properties

@synthesize	minimumValue = _minimumValue;
@synthesize	maximumValue = _maximumValue;
@synthesize	minimumDomain = _minimumDomain;
@synthesize	maximumDomain = _maximumDomain;
@synthesize	angle = _angle;

- (CGPoint)cartesianPoint {
	return CGPointMake(
					   cos(self.angle) * kRadius,
					   sin(self.angle) * kRadius);
}

- (void)setCartesianPoint:(CGPoint)point {
	CGFloat	previousAngle = self.angle,
			newAngle = atan(point.y/point.x);

	if (point.x < 0.0)
		newAngle = M_PI+newAngle;
	else if (point.y < 0)
		newAngle += 2 * M_PI;

	while (newAngle - previousAngle > M_PI)
		newAngle -= 2.0 * M_PI;

	while (previousAngle - newAngle > M_PI)
		newAngle += 2.0 * M_PI;

	self.angle = newAngle;
}

- (CGPoint)constrainedCartesianPoint {
	CGFloat radius = [Utility constrainValue:kRadius min:0.0 max:1.0];

	return CGPointMake(
					   cos(self.angle) * radius,
					   sin(self.angle) * radius);
}

- (void)setAngle:(CGFloat)angle {
	_angle = [Utility wrapValue:angle min:self.minimumDomain max:self.maximumDomain];
}

#pragma mark -
#pragma mark private properties

@synthesize	cachedBodyImage = _cachedBodyImage;
@synthesize	cachedHilightedBodyImage = _cachedHilightedBodyImage;
@synthesize	cachedThumbImage = _cachedThumbImage;
@synthesize	cachedHilightedThumbImage = _cachedHilightedThumbImage;

- (CGPoint)location {
	CGRect thumbRect = self.thumbRect;

	return [Utility mapPoint:self.constrainedCartesianPoint 
					  rangeV:CGRectMake(-1.0, -1.0, 2.0, 2.0) 
					  rangeR:[Utility shrinkRect:self.bodyRect 
											size:CGSizeMake(CGRectGetWidth(thumbRect) * 0.68,CGRectGetHeight(thumbRect) * 0.68)]];
}

- (void)setLocation:(CGPoint)point {
	CGRect thumbRect = self.thumbRect;

	self.cartesianPoint = [Utility mapPoint:point 
									 rangeV:[Utility shrinkRect:self.bodyRect 
														   size:CGSizeMake(CGRectGetWidth(thumbRect) * 0.68, CGRectGetHeight(thumbRect) * 0.68)]
									 rangeR:CGRectMake(-1.0, -1.0, 2.0, 2.0)];
}

- (UIImage *)cachedBodyImage {
	if (_cachedBodyImage == nil) {
		UIGraphicsBeginImageContext(self.bounds.size);
		if ([self drawBodyInRect:self.bodyRect hilighted:NO])
			_cachedBodyImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			_cachedBodyImage = self.cachedHilightedBodyImage;
		UIGraphicsEndImageContext();
	}

	return _cachedBodyImage;
}

- (UIImage *)cachedHilightedBodyImage {
	if (_cachedHilightedBodyImage == nil) {
		UIGraphicsBeginImageContext(self.bounds.size);
		if ([self drawBodyInRect:self.bodyRect hilighted:YES])
			_cachedHilightedBodyImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			_cachedHilightedBodyImage = self.cachedBodyImage;
		UIGraphicsEndImageContext();
	}

	return _cachedHilightedBodyImage;
}

- (UIImage *)cachedThumbImage {
	if (_cachedThumbImage == nil) {
		CGRect thumbRect = self.thumbRect;
		thumbRect.origin.x = 0;
		thumbRect.origin.y = 0;

		UIGraphicsBeginImageContext(thumbRect.size);
		if ([self drawThumbInRect:thumbRect hilighted:NO])
			_cachedThumbImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			_cachedThumbImage = self.cachedHilightedThumbImage;
		UIGraphicsEndImageContext();
	}
	return _cachedThumbImage;
}

- (UIImage *)cachedHilightedThumbImage {
	if (_cachedHilightedThumbImage == nil) {
		CGRect thumbRect = self.thumbRect;
		thumbRect.origin.x = 0;
		thumbRect.origin.y = 0;

		UIGraphicsBeginImageContext(thumbRect.size);
		if ([self drawThumbInRect:thumbRect hilighted:YES])
			_cachedHilightedThumbImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			_cachedHilightedThumbImage = self.cachedThumbImage;
		UIGraphicsEndImageContext();
	}

	return _cachedHilightedThumbImage;
}

#pragma mark -
#pragma mark creation and destruction

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		self.minimumValue = kDefaultMinimumValue;
		self.maximumValue = kDefaultMaximumValue;
		self.minimumDomain = kDefaultMinimumDomain;
		self.maximumDomain = kDefaultMaximumDomain;
	}

	return self;
}

#pragma mark -
#pragma mark NSCoding Protocol methods

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder]) != nil) {
		self.minimumValue = [Utility decodeDoubleWithDefault:coder key:kMinimumValueCodingKey defaultValue:kDefaultMinimumValue];
		self.maximumValue = [Utility decodeDoubleWithDefault:coder key:kMaximumValueCodingKey defaultValue:kDefaultMaximumValue];
		self.minimumDomain = [Utility decodeDoubleWithDefault:coder key:kMinimumDomainCodingKey defaultValue:kDefaultMinimumDomain];
		self.maximumDomain = [Utility decodeDoubleWithDefault:coder key:kMaximumDomainCodingKey defaultValue:kDefaultMaximumDomain];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeDouble:self.minimumValue forKey:kMinimumValueCodingKey];
	[coder encodeDouble:self.maximumValue forKey:kMaximumValueCodingKey];
	[coder encodeDouble:self.minimumDomain forKey:kMinimumDomainCodingKey];
	[coder encodeDouble:self.maximumDomain forKey:kMaximumDomainCodingKey];
}

#pragma mark -
#pragma mark UIControl

- (UIControlEvents)allControlEvents {
	return UIControlEventValueChanged;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint	point = [touch locationInView:self];

	self.location = point;

	[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self setNeedsDisplay];

	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	self.location = [touch locationInView:self];

	[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self setNeedsDisplay];

	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	self.location = [touch locationInView:self];

	[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self setNeedsDisplay];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
	[self setNeedsDisplay];
}

#pragma mark -
#pragma mark UIView

- (void)setFrame:(CGRect)rect {
	[self deleteThumbCache];
	[self deleteBodyCache];

	[super setFrame:rect];
}

- (void)setBounds:(CGRect)rect {
	[self deleteThumbCache];
	[self deleteBodyCache];

	[super setBounds:rect];
}

- (CGSize)sizeThatFits:(CGSize)size {
	return size.width < size.height
		? CGSizeMake(size.width, size.width)
		: CGSizeMake(size.height, size.height);
}

- (void)drawRect:(CGRect)rect {
	if (self.isOpaque) {
		[self.backgroundColor set];
		UIRectFill( rect );
	}

	if (self.state & UIControlStateHighlighted)
		[self.cachedBodyImage drawInRect:self.bounds];
	else
		[self.cachedHilightedBodyImage drawInRect:self.bounds];

	CGPoint	thumbLocation = self.location;
	CGRect	thumbRect = self.thumbRect;

	thumbRect.origin.x += thumbLocation.x;
	thumbRect.origin.y += thumbLocation.y;

	if (self.state & UIControlStateHighlighted)
		[self.cachedHilightedThumbImage drawInRect:thumbRect];
	else
		[self.cachedThumbImage drawInRect:thumbRect];
}

#pragma mark -
#pragma mark methods and properties to call when subclassing <NDRotator>.

- (void)deleteThumbCache {
	self.cachedThumbImage = nil;
	self.cachedHilightedThumbImage = nil;
}

- (void)deleteBodyCache {
	self.cachedBodyImage = nil;
	self.cachedHilightedBodyImage = nil;
}

#pragma mark -
#pragma mark methods to override to change look

- (CGRect)bodyRect {
	CGRect bodyBounds = self.bounds;

	bodyBounds.size.height = floorf(CGRectGetHeight(bodyBounds) * 0.95);
	bodyBounds.size.width = floorf(CGRectGetWidth(bodyBounds) * 0.95);
	bodyBounds.origin.y += ceilf(CGRectGetHeight(bodyBounds) * 0.01);
	bodyBounds.origin.x += ceilf((CGRectGetWidth(self.bounds) - CGRectGetWidth(bodyBounds)) * 0.5);
	bodyBounds = [Utility shrinkRect:bodyBounds size:CGSizeMake(1.0, 1.0)];

	return [Utility largestSquareWithinRect:bodyBounds];
}

- (CGRect)thumbRect {
	CGFloat	 thumbBoundsSize = MIN(CGRectGetWidth(self.bodyRect), CGRectGetHeight(self.bodyRect));
	CGFloat	 thumbDiameter = thumbBoundsSize * 0.25;

	if( thumbDiameter < 5.0 )
		thumbDiameter = 5.0;
	if( thumbDiameter > thumbBoundsSize * 0.5 )
		thumbDiameter = thumbBoundsSize * 0.5;

	CGFloat	thumbRadius = thumbDiameter/2.0;
	CGRect thumbBounds = CGRectMake(-thumbRadius, -thumbRadius, thumbDiameter, thumbDiameter);

	return [Utility shrinkRect:thumbBounds size:CGSizeMake(-1.0, -1.0)];
}

static CGGradientRef createShadowBodyGradient(CGColorSpaceRef colorSpace) {
	CGFloat	 locations[] = { 0.0, 0.3, 0.6, 1.0 };
	CGFloat	 components[sizeof(locations)/sizeof(*locations) * 4] = {
		0.0, 0.0, 0.0, 0.25,  // 0
		0.0, 0.0, 0.0, 0.125, // 1
		0.0, 0.0, 0.0, 0.0225, // 1
		0.0, 0.0, 0.0, 0.0 }; // 2

	return CGGradientCreateWithColorComponents(
											   colorSpace,
											   components,
											   locations,
											   sizeof(locations)/sizeof(*locations));
}

static CGGradientRef createHilightBodyGradient(CGColorSpaceRef colorSpace, BOOL hilighted) {
	CGFloat	 locations[] = { 0.0, 0.3, 0.6, 1.0 };
	CGFloat	 modifier = hilighted ? 1.0 : 0.33;
	CGFloat	 components[sizeof(locations)/sizeof(*locations) * 4] = {
		1.0, 1.0, 1.0, 0.0225,  // 0
		1.0, 1.0, 1.0, 0.33 * modifier, // 1
		1.0, 1.0, 1.0, 0.0225, // 1
		1.0, 1.0, 1.0, 0.0 }; // 2

	return CGGradientCreateWithColorComponents(
											   colorSpace,
											   components,
											   locations,
											   sizeof(locations)/sizeof(*locations));
}

- (BOOL)drawBodyInRect:(CGRect)rect hilighted:(BOOL)hilighted {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);

	CGFloat		startRadius = CGRectGetHeight(rect) * 0.50,
				bodyShadowColorComponents[] = { 0.0, 0.0, 0.0, 0.2 };

	CGPoint		startCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect)),
				shadowEndCenter = CGPointMake(startCenter.x, startCenter.y-0.05 * startRadius ),
				hilightEndCenter = CGPointMake(startCenter.x, startCenter.y+0.1 * startRadius );

	CGColorSpaceRef	colorSpace = CGColorGetColorSpace(self.backgroundColor.CGColor);

	if (hilighted)
		CGContextSetRGBFillColor(context, 0.9, 0.9, 0.9, 1.0);
	else
		CGContextSetRGBFillColor(context, 0.8, 0.8, 0.8, 1.0);

	CGContextSetRGBStrokeColor(context, 0.75, 0.75, 0.75, 1.0);

	CGContextRef baseContext = UIGraphicsGetCurrentContext();
	CGContextSaveGState(baseContext);

	CGColorRef baseColor = CGColorCreate(colorSpace, bodyShadowColorComponents);
	CGContextSetShadowWithColor(
								baseContext,
								CGSizeMake(0.0, startRadius * 0.05),
								2.0,
								baseColor);
	CGContextFillEllipseInRect(baseContext, rect);
	CGContextRestoreGState(baseContext);

	CGContextDrawRadialGradient(context, createHilightBodyGradient(colorSpace,hilighted), startCenter, startRadius, hilightEndCenter, startRadius * 0.85, 0.0);
	CGContextDrawRadialGradient(context, createShadowBodyGradient(colorSpace), startCenter, startRadius, shadowEndCenter, startRadius * 0.85, 0.0);

	CGContextSetAllowsAntialiasing(context, YES);
	CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 1.0);
	CGContextStrokeEllipseInRect(context, rect);

	CGContextRestoreGState(context);

	return YES;
}

static CGGradientRef createThumbGradient(CGColorSpaceRef colorSpace) {
	CGFloat			locations[] = { 0.0, 1.0 };
	CGFloat			components[sizeof(locations)/sizeof(*locations) * 4] = {
		0.72, 0.72, 0.72, 1.0, 0.99, 0.99, 0.99, 1.0
	};

	componentsForTint(components, 0.7);
	componentsForTint(components+4, 1.0);

	return CGGradientCreateWithColorComponents(colorSpace, components, locations, sizeof(locations)/sizeof(*locations));
}

- (BOOL)drawThumbInRect:(CGRect)rect hilighted:(BOOL)hilighted {
	if (!hilighted) {
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSaveGState(context);

		CGContextRef thumbContext = UIGraphicsGetCurrentContext();
		CGContextSaveGState(thumbContext);

		CGColorSpaceRef	colorSpace = CGColorGetColorSpace(self.backgroundColor.CGColor);
		CGRect			thumbBounds = rect;
		CGFloat			thumbDiam = CGRectGetWidth(thumbBounds);
		CGPoint			thumbCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

		CGContextAddEllipseInRect(thumbContext, thumbBounds);
		CGContextClip(thumbContext);

		CGPoint	startThumbPoint = CGPointMake(thumbCenter.x, thumbCenter.y-thumbDiam/2.0-thumbDiam * 1.3),
				endThumbPoint = CGPointMake(thumbCenter.x, thumbCenter.y+thumbDiam/2.0-thumbDiam);
		CGContextDrawRadialGradient(thumbContext, createThumbGradient(colorSpace), startThumbPoint, 1.3 * thumbDiam, endThumbPoint, thumbDiam, 0.0);

		CGContextRestoreGState(thumbContext);
		CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, 0.15);
		CGContextSetAllowsAntialiasing(context, YES);
		CGContextStrokeEllipseInRect(context, thumbBounds);
		CGContextRestoreGState(context);
	}

	return !hilighted;
}

@end
