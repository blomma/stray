#import "NDRotator.h"

// Contains the radius value of the receiver where 0.0 puts the thumb at the center and 1.0 puts the thumb at margin.
// The values can be greater than 1.0, to reflect user movements outside of the control.
static const CGFloat kRadius = 1.0;

static const CGFloat	kDefaultMinimumValue = 0.0,
						kDefaultMaximumValue = 1.0,
						kDefaultMinimumDomain = 0.0*M_PI,
						kDefaultMaximumDomain = 2.0*M_PI;

static NSString	* const kMinimumValueCodingKey = @"minimumValue",
				* const kMaximumValueCodingKey = @"maximumValue",
				* const kMinimumDomainCodingKey = @"minimumDomain",
				* const kMaximumDomainCodingKey = @"maximumDomain";

static void componentsForTint(CGFloat * component, CGFloat value) {
	component[0] = value*(0.55*0.5);
	component[1] = value;
	component[2] = value*(0.55);
}

static inline CGFloat mathMod(CGFloat x, CGFloat y) {
	CGFloat r = fmodf(x,y);

	return r < 0.0
		? r + y
		: r;
}

static CGFloat constrainValue(CGFloat value, CGFloat min, CGFloat max) {
	return value < min
		? min
		: (value > max ? max : value);
}

static CGFloat wrapValue(CGFloat value, CGFloat min, CGFloat max) {
	return mathMod(value-min,max-min)+min;
}

static CGFloat mapValue(CGFloat value, CGFloat minValue, CGFloat maxValue, CGFloat minR, CGFloat maxR) {
	return ((value-minValue)/(maxValue-minValue)) * (maxR - minR) + minR;
}

static CGPoint mapPoint(const CGPoint value, const CGRect rangeV, const CGRect rangeR) {
	return CGPointMake(
					   mapValue(
								value.x,
								CGRectGetMinX(rangeV),
								CGRectGetMaxX(rangeV),
								CGRectGetMinX(rangeR),
								CGRectGetMaxX(rangeR)),
					   mapValue(
								value.y,
								CGRectGetMinY(rangeV),
								CGRectGetMaxY(rangeV),
								CGRectGetMinY(rangeR),
								CGRectGetMaxY(rangeR)));
}

static CGRect shrinkRect(const CGRect v, CGSize s) {
	return CGRectMake(
					  CGRectGetMinX(v)+s.width,
					  CGRectGetMinY(v)+s.height,
					  CGRectGetWidth(v)-2.0*s.width,
					  CGRectGetHeight(v)-2.0*s.height);
}

static CGRect largestSquareWithinRect(const CGRect r) {
	CGFloat	scale = MIN(CGRectGetWidth(r), CGRectGetHeight(r));

	return CGRectMake(
					  CGRectGetMinX(r),
					  CGRectGetMinY(r),
					  scale,
					  scale);
}

@interface NDRotator ()
{
@private
	UIImage	* cachedBodyImage,
			* cachedHilightedBodyImage,
			* cachedThumbImage,
			* cachedHilightedThumbImage;
}
@end

@implementation NDRotator

@synthesize	minimumValue,
			maximumValue,
			minimumDomain,
			maximumDomain,
			angle,
			touchDownAngle,
			touchDownYLocation;

#pragma mark -
#pragma mark public properties

- (CGPoint)cartesianPoint {
	return CGPointMake(
					   cos(self.angle)*kRadius,
					   sin(self.angle)*kRadius);
}

- (void)setCartesianPoint:(CGPoint)point {
	CGFloat	previousAngle = self.angle,
			newAngle = atan(point.y/point.x);

	if (point.x < 0.0)
		newAngle = M_PI+newAngle;
	else if (point.y < 0)
		newAngle += 2*M_PI;

	while (newAngle - previousAngle > M_PI)
		newAngle -= 2.0*M_PI;

	while (previousAngle - newAngle > M_PI)
		newAngle += 2.0*M_PI;

	self.angle = newAngle;
}

- (CGPoint)constrainedCartesianPoint {
	CGFloat	radius = constrainValue(kRadius, 0.0, 1.0 );

	return CGPointMake(
					   cos(self.angle)*radius,
					   sin(self.angle)*radius);
}

- (void)setAngle:(CGFloat)v {
	angle = wrapValue(v, self.minimumDomain, self.maximumDomain);
}

#pragma mark -
#pragma mark private properties

- (CGPoint)location {
	CGRect thumbRect = self.thumbRect;

	return mapPoint(
					self.constrainedCartesianPoint,
					CGRectMake(-1.0, -1.0, 2.0, 2.0),
					shrinkRect(
							   self.bodyRect,
							   CGSizeMake(CGRectGetWidth(thumbRect)*0.68,CGRectGetHeight(thumbRect)*0.68)));
}

- (void)setLocation:(CGPoint)point {
	CGRect thumbRect = self.thumbRect;

	self.cartesianPoint = mapPoint(
								   point,
								   shrinkRect(self.bodyRect,
											  CGSizeMake(CGRectGetWidth(thumbRect)*0.68,
														 CGRectGetHeight(thumbRect)*0.68)),
								   CGRectMake(-1.0, -1.0, 2.0, 2.0));
}

- (UIImage *)cachedBodyImage {
	if (cachedBodyImage == nil) {
		UIGraphicsBeginImageContext(self.bounds.size);
		if ([self drawBodyInRect:self.bodyRect hilighted:NO])
			cachedBodyImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedBodyImage = self.cachedHilightedBodyImage;
		UIGraphicsEndImageContext();
	}

	return cachedBodyImage;
}

- (UIImage *)cachedHilightedBodyImage {
	if (cachedHilightedBodyImage == nil) {
		UIGraphicsBeginImageContext(self.bounds.size);
		if ([self drawBodyInRect:self.bodyRect hilighted:YES])
			cachedHilightedBodyImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedHilightedBodyImage = self.cachedBodyImage;
		UIGraphicsEndImageContext();
	}

	return cachedHilightedBodyImage;
}

- (UIImage *)cachedThumbImage {
	if (cachedThumbImage == nil) {
		CGRect thumbRect = self.thumbRect;
		thumbRect.origin.x = 0;
		thumbRect.origin.y = 0;

		UIGraphicsBeginImageContext(thumbRect.size);
		if ([self drawThumbInRect:thumbRect hilighted:NO])
			cachedThumbImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedThumbImage = self.cachedHilightedThumbImage;
		UIGraphicsEndImageContext();
	}
	return cachedThumbImage;
}

- (UIImage *)cachedHilightedThumbImage {
	if (cachedHilightedThumbImage == nil) {
		CGRect thumbRect = self.thumbRect;
		thumbRect.origin.x = 0;
		thumbRect.origin.y = 0;

		UIGraphicsBeginImageContext(thumbRect.size);
		if ([self drawThumbInRect:thumbRect hilighted:YES])
			cachedHilightedThumbImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedHilightedThumbImage = self.cachedThumbImage;
		UIGraphicsEndImageContext();
	}

	return cachedHilightedThumbImage;
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

static CGFloat decodeDoubleWithDefault(NSCoder * coder, NSString * key, CGFloat defaultValue) {
	NSNumber * value = [coder decodeObjectForKey:key];

	return value != nil
		? value.doubleValue
		: defaultValue;
}

static BOOL decodeBooleanWithDefault(NSCoder * coder, NSString * key, BOOL defaultValue) {
	NSNumber * value = [coder decodeObjectForKey:key];

	return value != nil
		? value.boolValue
		: defaultValue;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder]) != nil) {
		self.minimumValue = decodeDoubleWithDefault( coder, kMinimumValueCodingKey, kDefaultMinimumValue );
		self.maximumValue = decodeDoubleWithDefault( coder, kMaximumValueCodingKey, kDefaultMaximumValue );
		self.minimumDomain = decodeDoubleWithDefault( coder, kMinimumDomainCodingKey, kDefaultMinimumDomain );
		self.maximumDomain = decodeDoubleWithDefault( coder, kMaximumDomainCodingKey, kDefaultMaximumDomain );
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

	self.touchDownYLocation = point.y;
	self.touchDownAngle = self.angle;
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
		[[self cachedHilightedThumbImage] drawInRect:thumbRect];
	else
		[[self cachedThumbImage] drawInRect:thumbRect];
}

#pragma mark -
#pragma mark methods and properties to call when subclassing <NDRotator>.

- (void)deleteThumbCache {
	cachedThumbImage = nil;
	cachedHilightedThumbImage = nil;
}

- (void)deleteBodyCache {
	cachedBodyImage = nil;
	cachedHilightedBodyImage = nil;
}

#pragma mark -
#pragma mark methods to override to change look

- (CGRect)bodyRect {
	CGRect bodyBounds = self.bounds;

	bodyBounds.size.height = floorf(CGRectGetHeight(bodyBounds) * 0.95);
	bodyBounds.size.width = floorf(CGRectGetWidth(bodyBounds) * 0.95);
	bodyBounds.origin.y += ceilf(CGRectGetHeight(bodyBounds) * 0.01);
	bodyBounds.origin.x += ceilf((CGRectGetWidth(self.bounds) - CGRectGetWidth(bodyBounds)) * 0.5);
	bodyBounds = shrinkRect(bodyBounds, CGSizeMake(1.0,1.0));

	return largestSquareWithinRect(bodyBounds);
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

	return shrinkRect(thumbBounds, CGSizeMake(-1.0,-1.0));
}

static CGGradientRef createShadowBodyGradient(CGColorSpaceRef colorSpace) {
	CGFloat	 locations[] = { 0.0, 0.3, 0.6, 1.0 };
	CGFloat	 components[sizeof(locations)/sizeof(*locations)*4] = {
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
	CGFloat	 components[sizeof(locations)/sizeof(*locations)*4] = {
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
				shadowEndCenter = CGPointMake(startCenter.x, startCenter.y-0.05*startRadius ),
				hilightEndCenter = CGPointMake(startCenter.x, startCenter.y+0.1*startRadius );

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
								CGSizeMake(0.0, startRadius*0.05),
								2.0,
								baseColor);
	CGContextFillEllipseInRect(baseContext, rect);
	CGContextRestoreGState(baseContext);

	CGContextDrawRadialGradient(context, createHilightBodyGradient(colorSpace,hilighted), startCenter, startRadius, hilightEndCenter, startRadius*0.85, 0.0);
	CGContextDrawRadialGradient(context, createShadowBodyGradient(colorSpace), startCenter, startRadius, shadowEndCenter, startRadius*0.85, 0.0);

	CGContextSetAllowsAntialiasing(context, YES);
	CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 1.0);
	CGContextStrokeEllipseInRect(context, rect);

	CGContextRestoreGState(context);

	return YES;
}

static CGGradientRef createThumbGradient(CGColorSpaceRef colorSpace) {
	CGFloat			locations[] = { 0.0, 1.0 };
	CGFloat			components[sizeof(locations)/sizeof(*locations)*4] = {
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

		CGPoint	startThumbPoint = CGPointMake(thumbCenter.x, thumbCenter.y-thumbDiam/2.0-thumbDiam*1.3),
				endThumbPoint = CGPointMake(thumbCenter.x, thumbCenter.y+thumbDiam/2.0-thumbDiam);
		CGContextDrawRadialGradient(thumbContext, createThumbGradient(colorSpace), startThumbPoint, 1.3*thumbDiam, endThumbPoint, thumbDiam, 0.0);

		CGContextRestoreGState(thumbContext);
		CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.3, 0.15);
		CGContextSetAllowsAntialiasing(context, YES);
		CGContextStrokeEllipseInRect(context, thumbBounds);
		CGContextRestoreGState(context);
	}

	return !hilighted;
}

@end