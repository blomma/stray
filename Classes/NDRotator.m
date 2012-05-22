#import "NDRotator.h"

// Contains the radius value of the receiver where 0.0 puts the thumb at the center and 1.0 puts the thumb at margin. 
// The values can be greater than 1.0, to reflect user movements outside of the control.
static const CGFloat kRadius = 1.0;

static const CGFloat	kDefaultMinimumValue = 0.0,
						kDefaultMaximumValue = 1.0,
						kDefaultMinimumDomain = 0.0*M_PI,
						kDefaultMaximumDomain = 2.0*M_PI;

static enum NDThumbTint	kDefaultThumbTint = NDThumbTintLime;

static NSString	* const kMinimumValueCodingKey = @"minimumValue",
				* const kMaximumValueCodingKey = @"maximumValue",
				* const kMinimumDomainCodingKey = @"minimumDomain",
				* const kMaximumDomainCodingKey = @"maximumDomain",
				* const kThumbTintCodingKey = @"thumbTint";

static NSString	* kThumbTintStr[] = { @"grey", @"red", @"green", @"blue", @"yellow", @"magenta", @"teal", @"orange", @"pink", @"lime", @"spring green", @"purple", @"aqua", @"black" };

static const CGFloat kThumbTintSaturation = 0.45;

static void componentsForTint( CGFloat * comp, CGFloat v, enum NDThumbTint t )
{
	switch(t)
	{
		default:
		case NDThumbTintGrey:
			comp[0] = v*0.9;
			comp[1] = v*0.9;
			comp[2] = v*0.9;
			break;
		case NDThumbTintRed:
			comp[0] = v;
			comp[1] = v*(1.0-kThumbTintSaturation);
			comp[2] = v*(1.0-kThumbTintSaturation);
			break;
		case NDThumbTintGreen:
			comp[0] = v*(1.0-kThumbTintSaturation);
			comp[1] = v;
			comp[2] = v*(1.0-kThumbTintSaturation);
			break;
		case NDThumbTintBlue:
			comp[0] = v*(1.0-kThumbTintSaturation);
			comp[1] = v*(1.0-kThumbTintSaturation);
			comp[2] = v;
			break;
		case NDThumbTintTeal:
			comp[0] = v*(1.0-kThumbTintSaturation);
			comp[1] = v;
			comp[2] = v;
			break;
		case NDThumbTintMagenta:
			comp[0] = v;
			comp[1] = v*(1.0-kThumbTintSaturation);
			comp[2] = v;
			break;
		case NDThumbTintYellow:
			comp[0] = v;
			comp[1] = v;
			comp[2] = v*(1.0-kThumbTintSaturation);
			break;
		case NDThumbTintOrange:
			comp[0] = v;
			comp[1] = v*(1.0-kThumbTintSaturation*0.5);
			comp[2] = v*(1.0-kThumbTintSaturation);
			break;
		case NDThumbTintPink:
			comp[0] = v;
			comp[1] = v*(1.0-kThumbTintSaturation);
			comp[2] = v*(1.0-kThumbTintSaturation*0.5);
			break;
		case NDThumbTintLime:
			comp[0] = v*(1.0-kThumbTintSaturation*0.5);
			comp[1] = v;
			comp[2] = v*(1.0-kThumbTintSaturation);
			break;
		case NDThumbTintSpringGreen:
			comp[0] = v*(1.0-kThumbTintSaturation);
			comp[1] = v;
			comp[2] = v*(1.0-kThumbTintSaturation*0.5);
			break;
		case NDThumbTintPurple:
			comp[0] = v*(1.0-kThumbTintSaturation*0.5);
			comp[1] = v*(1.0-kThumbTintSaturation);
			comp[2] = v;
			break;
		case NDThumbTintAqua:
			comp[0] = v*(1.0-kThumbTintSaturation);
			comp[1] = v*(1.0-kThumbTintSaturation*0.5);
			comp[2] = v;
			break;
		case NDThumbTintBlack:
			comp[0] = v*0.7;
			comp[1] = v*0.7;
			comp[2] = v*0.7;
			break;
	}
}

static inline CGFloat mathMod(CGFloat x, CGFloat y) { 
	CGFloat r = fmodf(x,y); 
	
	return r < 0.0 ? r + y : r; 
}

static CGFloat constrainValue(CGFloat value, CGFloat min, CGFloat max) { 
	return value < min ? min : (value > max ? max : value); 
}

static CGFloat wrapValue(CGFloat v, CGFloat min, CGFloat max) { 
	return mathMod(v-min,max-min)+min; 
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
	CGFloat	touchDownAngle,
			touchDownYLocation;

	UIImage	* cachedBodyImage,
			* cachedHilightedBodyImage,
			* cachedThumbImage,
			* cachedHilightedThumbImage;
}
@property(assign) CGPoint	location;

@property(assign) CGFloat	touchDownAngle,
							touchDownYLocation;

@property(readonly) UIImage	* cachedBodyImage,
							* cachedHilightedBodyImage,
							* cachedThumbImage,
							* cachedHilightedThumbImage;
@end

@implementation NDRotator

@synthesize	minimumValue,
			maximumValue,
			minimumDomain,
			maximumDomain,
			angle,
			thumbTint;

#pragma mark -
#pragma mark manully implemented properties

- (CGPoint)cartesianPoint { 
	return CGPointMake(
					   cos(self.angle)*kRadius, 
					   sin(self.angle)*kRadius); 
}

- (CGPoint)constrainedCartesianPoint {
	CGFloat	radius = constrainValue(kRadius, 0.0, 1.0 );

	return CGPointMake(
					   cos(self.angle)*radius,
					   sin(self.angle)*radius);
}

- (void)setCartesianPoint:(CGPoint)point {
	CGFloat	previousAngle = self.angle,
			newAngle = atan(point.y/point.x);
	
	if(point.x < 0.0)
		newAngle = M_PI+newAngle;
	else if(point.y < 0)
		newAngle += 2*M_PI;

	while(newAngle - previousAngle > M_PI)
		newAngle -= 2.0*M_PI;
	
	while(previousAngle - newAngle > M_PI)
		newAngle += 2.0*M_PI;
	
	self.angle = newAngle;
}

- (void)setAngle:(CGFloat)v {
	angle = wrapValue(v, self.minimumDomain, self.maximumDomain);
}

- (void)setThumbTint:(enum NDThumbTint)value {
	thumbTint = value;

	[self deleteThumbCache];
}

#pragma mark -
#pragma mark creation and destruction
- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame]) != nil) {
		self.minimumValue = kDefaultMinimumValue;
		self.maximumValue = kDefaultMaximumValue;
		self.minimumDomain = kDefaultMinimumDomain;
		self.maximumDomain = kDefaultMaximumDomain;
		self.thumbTint = kDefaultThumbTint;
	}
	
	return self;
}

#pragma mark -
#pragma mark NSCoding Protocol methods

static CGFloat decodeDoubleWithDefault(NSCoder * coder, NSString * key, CGFloat defaultValue) {
	NSNumber * value = [coder decodeObjectForKey:key];

	return value != nil ? value.doubleValue : defaultValue;
}

static BOOL decodeBooleanWithDefault(NSCoder * coder, NSString * key, BOOL defaultValue) {
	NSNumber * value = [coder decodeObjectForKey:key];

	return value != nil ? value.boolValue : defaultValue;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super initWithCoder:coder]) != nil) {
		self.minimumValue = decodeDoubleWithDefault( coder, kMinimumValueCodingKey, kDefaultMinimumValue );
		self.maximumValue = decodeDoubleWithDefault( coder, kMaximumValueCodingKey, kDefaultMaximumValue );
		self.minimumDomain = decodeDoubleWithDefault( coder, kMinimumDomainCodingKey, kDefaultMinimumDomain );
		self.maximumDomain = decodeDoubleWithDefault( coder, kMaximumDomainCodingKey, kDefaultMaximumDomain );
		self.thumbTint = kDefaultThumbTint;
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

- (void)cancelTrackingWithEvent:(UIEvent *)anEvent { 
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
	if( self.isOpaque )
	{
		[self.backgroundColor set];
		UIRectFill( rect );
	}
	
	if( self.state & UIControlStateHighlighted )
		[self.cachedBodyImage drawInRect:self.bounds];
	else
		[self.cachedHilightedBodyImage drawInRect:self.bounds];
	CGPoint		theThumbLocation = self.location;
	CGRect		theThumbRect = self.thumbRect;
	theThumbRect.origin.x += theThumbLocation.x;
	theThumbRect.origin.y += theThumbLocation.y;
	if( self.state & UIControlStateHighlighted )
		[[self cachedHilightedThumbImage] drawInRect:theThumbRect];
	else
		[[self cachedThumbImage] drawInRect:theThumbRect];
}

#pragma mark -
#pragma mark  methods and properties to call when subclassing <NDRotator>.

- (void)deleteThumbCache
{
	cachedThumbImage = nil;
	cachedHilightedThumbImage = nil;
}

- (void)deleteBodyCache
{
	cachedBodyImage = nil;
	cachedHilightedBodyImage = nil;
}

#pragma mark -
#pragma mark methods to override to change look

- (CGRect)bodyRect
{
	CGRect	bodyBounds = self.bounds;

	bodyBounds.size.height = floorf(CGRectGetHeight(bodyBounds) * 0.95);
	bodyBounds.size.width = floorf(CGRectGetWidth(bodyBounds) * 0.95);
	bodyBounds.origin.y += ceilf(CGRectGetHeight(bodyBounds) * 0.01);
	bodyBounds.origin.x += ceilf((CGRectGetWidth(self.bounds) - CGRectGetWidth(bodyBounds)) * 0.5);
	bodyBounds = shrinkRect(bodyBounds, CGSizeMake(1.0,1.0));

	return largestSquareWithinRect(bodyBounds);
}

- (CGRect)thumbRect
{
	CGFloat	 thumbBoundsSize = MIN(CGRectGetWidth(self.bodyRect), CGRectGetHeight(self.bodyRect));
	CGFloat	 thumbDiameter = thumbBoundsSize * 0.25;

	if( thumbDiameter < 5.0 )
		thumbDiameter = 5.0;
	if( thumbDiameter > thumbBoundsSize * 0.5 )
		thumbDiameter = thumbBoundsSize * 0.5;

	CGFloat	 thumbRadius = thumbDiameter/2.0;
	CGRect thumbBounds = CGRectMake(-thumbRadius, -thumbRadius, thumbDiameter, thumbDiameter);

	return shrinkRect(thumbBounds, CGSizeMake(-1.0,-1.0));
}

static CGGradientRef shadowBodyGradient(CGColorSpaceRef colorSpace)
{
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

static CGGradientRef hilightBodyGradient(CGColorSpaceRef colorSpace, BOOL hilighted)
{
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
	CGContextSetShadowWithColor(
								baseContext, 
								CGSizeMake(0.0, startRadius*0.05), 
								2.0, 
								CGColorCreate(colorSpace, bodyShadowColorComponents));
	CGContextFillEllipseInRect(baseContext, rect);
	CGContextRestoreGState(baseContext);
	
//	CGContextDrawRadialGradient( context, hilightBodyGradient(colorSpace,hilighted), startCenter, startRadius, hilightEndCenter, startRadius*0.85, 0.0 );
//	CGContextDrawRadialGradient( context, shadowBodyGradient(colorSpace), startCenter, startRadius, shadowEndCenter, startRadius*0.85, 0.0 );
	
	CGContextSetAllowsAntialiasing(context, YES);
	CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 1.0);
	CGContextStrokeEllipseInRect(context, rect);
	
	CGContextRestoreGState(context);

	return YES;
}

static CGGradientRef thumbGradient( CGColorSpaceRef aColorSpace, enum NDThumbTint aThumbTint )
{
	CGFloat			theLocations[] = { 0.0, 1.0 };
	CGFloat			theComponents[sizeof(theLocations)/sizeof(*theLocations)*4] = {0.72, 0.72, 0.72, 1.0, 0.99, 0.99, 0.99, 1.0 };
	
	componentsForTint( theComponents, 0.7, aThumbTint );
	componentsForTint( theComponents+4, 1.0, aThumbTint );
	return CGGradientCreateWithColorComponents( aColorSpace, theComponents, theLocations, sizeof(theLocations)/sizeof(*theLocations) );
}

- (BOOL)drawThumbInRect:(CGRect)aRect hilighted:(BOOL)aHilighted
{
	if( !aHilighted )
	{
		CGContextRef	theContext = UIGraphicsGetCurrentContext();
		CGContextSaveGState( theContext );
		
		CGContextRef	theThumbContext = UIGraphicsGetCurrentContext();
		CGContextSaveGState( theThumbContext );
		
		CGColorSpaceRef	theColorSpace = CGColorGetColorSpace(self.backgroundColor.CGColor);
		CGRect			theThumbBounds = aRect;
		CGFloat			theThumbDiam = CGRectGetWidth( theThumbBounds );
		CGPoint			theCenter = CGPointMake(CGRectGetMidX(aRect), CGRectGetMidY(aRect) );
		
		CGContextAddEllipseInRect( theThumbContext, theThumbBounds );
		CGContextClip( theThumbContext );
		
		CGPoint			theStartThumbPoint = CGPointMake(theCenter.x, theCenter.y-theThumbDiam/2.0-theThumbDiam*1.3),
		theEndThumbPoint = CGPointMake(theCenter.x, theCenter.y+theThumbDiam/2.0-theThumbDiam);
		CGContextDrawRadialGradient( theThumbContext, thumbGradient( theColorSpace, self.thumbTint ), theStartThumbPoint, 1.3*theThumbDiam, theEndThumbPoint, theThumbDiam, 0.0 );
		
		CGContextRestoreGState( theThumbContext );
		CGContextSetRGBStrokeColor( theContext, 0.3, 0.3, 0.3, 0.15 );
		CGContextSetAllowsAntialiasing( theContext, YES );
		CGContextStrokeEllipseInRect( theContext, theThumbBounds );
		CGContextRestoreGState( theContext );
	}
	return !aHilighted;
}

#pragma mark -
#pragma mark Private

@synthesize	touchDownAngle,
			touchDownYLocation;

- (CGPoint)location {
	CGRect thumbRect = self.thumbRect;

	return mapPoint( self.constrainedCartesianPoint, CGRectMake(-1.0, -1.0, 2.0, 2.0), shrinkRect(self.bodyRect, CGSizeMake(CGRectGetWidth(thumbRect)*0.68,CGRectGetHeight(thumbRect)*0.68) ) );
}

- (void)setLocation:(CGPoint)point {
		CGRect thumbRect = self.thumbRect;
		self.cartesianPoint = mapPoint(point, shrinkRect(self.bodyRect, CGSizeMake(CGRectGetWidth(thumbRect)*0.68,CGRectGetHeight(thumbRect)*0.68) ), CGRectMake(-1.0, -1.0, 2.0, 2.0 ) );
}

- (UIImage *)cachedBodyImage {
	if (cachedBodyImage == nil)
	{
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
	if (cachedHilightedBodyImage == nil)
	{
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
	if (cachedThumbImage == nil)
	{
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
	if (cachedHilightedThumbImage == nil)
	{
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

@end
