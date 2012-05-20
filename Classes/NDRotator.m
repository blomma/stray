/*
 NDRotator.m
 RotatingControllerView
 
 Created by Nathan Day on 7/07/11.
 Copyright 2011 Nathan Day. All rights reserved.
 */

#import "NDRotator.h"


static const CGFloat		kDefaultRadius = 1.0,
kDefaultLinearSensitivity = 0.05,
kDefaultMinimumValue = 0.0,
kDefaultMaximumValue = 1.0,
kDefaultMinimumDomain = 0.0*M_PI,
kDefaultMaximumDomain = 2.0*M_PI;
static enum NDThumbTint		kDefaultThumbTint = NDThumbTintLime;
static const BOOL			kDefaultContinuousValue = YES;

static NSString			* const kRadiusCodingKey = @"radius",
* const kLinearSensitivityCodingKey = @"linearSensitivity",
* const kMinimumValueCodingKey = @"minimumValue",
* const kMaximumValueCodingKey = @"maximumValue",
* const kMinimumDomainCodingKey = @"minimumDomain",
* const kMaximumDomainCodingKey = @"maximumDomain",
* const kThumbTintCodingKey = @"thumbTint",
* const kContinuousCodingKey = @"continuous";

static NSString			* kThumbTintStr[] = { @"grey", @"red", @"green", @"blue", @"yellow", @"magenta", @"teal", @"orange", @"pink", @"lime", @"spring green", @"purple", @"aqua", @"black" };

static const CGFloat		kThumbTintSaturation = 0.45;

static NSString * stringForInteger( NSUInteger aValue, NSString ** aStrList, NSUInteger aCount ) { return aValue < aCount ? aStrList[aValue] : nil; }

static NSUInteger integerValueForString( NSString * aStr, NSString ** aStrList, NSUInteger aCount, NSUInteger aDefault )
{
	for( NSInteger i = 0; i < aCount; i++ )
	{
		if( [aStr isEqualToString:aStrList[i]] )
			return i;
	}
	return aDefault;
}

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

static inline CGFloat mathMod(CGFloat x, CGFloat y) { CGFloat r = fmodf(x,y); return r < 0.0 ? r + y : r; }
static CGFloat constrainValue( CGFloat v, CGFloat min, CGFloat max ) { return v < min ? min : (v > max ? max : v); }
static CGFloat wrapValue( CGFloat v, CGFloat min, CGFloat max ) { return mathMod(v-min,max-min)+min; }
static CGFloat mapValue( CGFloat v, CGFloat minV, CGFloat maxV, CGFloat minR, CGFloat maxR ) { return ((v-minV)/(maxV-minV)) * (maxR - minR) + minR; }
static CGPoint constrainPoint( const CGPoint v, const CGRect m )
{
	return CGPointMake( constrainValue( v.x, CGRectGetMinX(m), CGRectGetMaxX(m) ), constrainValue( v.y, CGRectGetMinY(m), CGRectGetMaxY(m) ) );
}
static CGPoint mapPoint( const CGPoint v, const CGRect rangeV, const CGRect rangeR )
{
	return CGPointMake(
					   mapValue( v.x, CGRectGetMinX(rangeV), CGRectGetMaxX(rangeV), CGRectGetMinX(rangeR), CGRectGetMaxX(rangeR)),
					   mapValue( v.y, CGRectGetMinY(rangeV), CGRectGetMaxY(rangeV), CGRectGetMinY(rangeR), CGRectGetMaxY(rangeR)));
}

static CGRect shrinkRect( const CGRect v, CGSize s )
{
	return CGRectMake( CGRectGetMinX(v)+s.width, CGRectGetMinY(v)+s.height, CGRectGetWidth(v)-2.0*s.width, CGRectGetHeight(v)-2.0*s.height );
}

static CGRect largestSquareWithinRect( const CGRect r )
{
	CGFloat		theScale = MIN( CGRectGetWidth(r), CGRectGetHeight(r) );
	return CGRectMake( CGRectGetMinX(r), CGRectGetMinY(r), theScale, theScale );
}

static CGFloat differenceMagnitude( CGFloat a, CGFloat b ) { return a > b ? a - b : b - a; }

static CGFloat largestFloat( const CGFloat * f, NSUInteger c )
{
	CGFloat		r = 1.0;
	for( NSUInteger i = 0; i < c; i++ )
	{
		if( f[i] > r )
			r = f[i];
	}
	return r;
}

static CGFloat meanFloat( const CGFloat * f, NSUInteger c )
{
	CGFloat		r = 0.0;
	for( NSUInteger i = 0; i < c; i++ )
		r += f[i];
	return r/(CGFloat)c;
}

@interface NDRotator ()
{
@private
	CGFloat			touchDownAngle,
	touchDownYLocation;
	UIImage			* cachedBodyImage,
	* cachedHilightedBodyImage,
	* cachedThumbImage,
	* cachedHilightedThumbImage;
}
@property(assign) CGPoint		location;
@property(assign) CGFloat		touchDownAngle,
touchDownYLocation;
@property(readonly) UIImage		* cachedBodyImage,
* cachedHilightedBodyImage,
* cachedThumbImage,
* cachedHilightedThumbImage;

@end

@implementation NDRotator

@synthesize		minimumValue,
maximumValue,
minimumDomain,
maximumDomain,
angle,
radius,
linearSensitivity,
continuous,
thumbTint;

#pragma mark -
#pragma mark manully implemented properties

- (CGFloat)radius { return 1.0; }

- (CGPoint)cartesianPoint { return CGPointMake(cos(self.angle)*self.radius, sin(self.angle)*self.radius ); }
- (CGPoint)constrainedCartesianPoint
{
	CGFloat			theRadius = constrainValue(self.radius, 0.0, 1.0 );
	return CGPointMake(cos(self.angle)*theRadius,sin(self.angle)*theRadius );
}

- (void)setCartesianPoint:(CGPoint)aPoint
{
	CGFloat		thePreviousAngle = angle,
	theAngle = atan( aPoint.y/aPoint.x );
	
	if( aPoint.x < 0.0 )
		theAngle = M_PI + theAngle;
	else if( aPoint.y < 0 )
		theAngle += 2*M_PI;
	
	while( theAngle - thePreviousAngle > M_PI )
		theAngle -= 2.0*M_PI;
	
	while( thePreviousAngle - theAngle > M_PI )
		theAngle += 2.0*M_PI;
	
	self.angle = theAngle;
	self.radius = sqrt( aPoint.x*aPoint.x + aPoint.y*aPoint.y );
}

- (CGFloat)value { return mapValue(self.angle, self.minimumDomain, self.maximumDomain, self.minimumValue, self.maximumValue ); }

- (void)setValue:(CGFloat)aValue
{
	CGFloat			theMinium = self.minimumValue,
	theMaximum = self.maximumValue;
	
			self.angle = mapValue(constrainValue( self.angle, self.minimumValue, self.maximumDomain), theMinium, theMaximum, self.minimumValue, self.maximumDomain );
}

- (void)setAngle:(CGFloat)anAngle
{
	angle = wrapValue( anAngle, self.minimumDomain, self.maximumDomain );
}

- (void)setThumbTint:(enum NDThumbTint)aThumbTint
{
	thumbTint = aThumbTint;
	[self deleteThumbCache];
}

#pragma mark -
#pragma mark creation and destruction
- (id)initWithFrame:(CGRect)aFrame
{
	if( (self = [super initWithFrame:aFrame]) != nil )
	{
		self.radius = kDefaultRadius;
		self.linearSensitivity = kDefaultLinearSensitivity;
		self.minimumValue = kDefaultMinimumValue;
		self.maximumValue = kDefaultMaximumValue;
		self.minimumDomain = kDefaultMinimumDomain;
		self.maximumDomain = kDefaultMaximumDomain;
		self.thumbTint = kDefaultThumbTint;
		self.continuous = kDefaultContinuousValue;
	}
	
	return self;
}

- (NSString *)description
{
	char					theAutoResizeMaskStr[20] = "";
	UIViewAutoresizing		theAutoResizeMask = self.autoresizingMask;
	
	if( (theAutoResizeMask & UIViewAutoresizingFlexibleRightMargin) == 0 )
	{
		if( *theAutoResizeMaskStr != '\0' ) strcat( theAutoResizeMaskStr, "*" );
		strcat( theAutoResizeMaskStr, "RM" );
	}
	if( (theAutoResizeMask & UIViewAutoresizingFlexibleWidth) == 0 )
	{
		if( *theAutoResizeMaskStr != '\0' ) strcat( theAutoResizeMaskStr, "*" );
		strcat( theAutoResizeMaskStr, "W" );
	}
	if( (theAutoResizeMask & UIViewAutoresizingFlexibleLeftMargin) == 0 )
	{
		if( *theAutoResizeMaskStr != '\0' ) strcat( theAutoResizeMaskStr, "*" );
		strcat( theAutoResizeMaskStr, "LM" );
	}
	
	if( (theAutoResizeMask & UIViewAutoresizingFlexibleTopMargin) == 0 )
	{
		if( *theAutoResizeMaskStr != '\0' ) strcat( theAutoResizeMaskStr, "*" );
		strcat( theAutoResizeMaskStr, "TM" );
	}
	if( (theAutoResizeMask & UIViewAutoresizingFlexibleHeight) == 0 )
	{
		if( *theAutoResizeMaskStr != '\0' ) strcat( theAutoResizeMaskStr, "*" );
		strcat( theAutoResizeMaskStr, "H" );
	}
	if( (theAutoResizeMask & UIViewAutoresizingFlexibleBottomMargin) == 0 )
	{
		if( *theAutoResizeMaskStr != '\0' ) strcat( theAutoResizeMaskStr, "*" );
		strcat( theAutoResizeMaskStr, "BM" );
	}
	
	return [NSString stringWithFormat:@"<UISlider: %p; frame = (%.0f %.0f; %.0f %.0f); opaque = %s; autoresize = %s; layer = <CALayer: %p>; value: %.2f; angle: %.2f; radius: %.2f; x: %.2f; y: %.2f>",
			self,
			CGRectGetMinX(self.frame),
			CGRectGetMinY(self.frame),
			CGRectGetWidth(self.frame),
			CGRectGetHeight(self.frame),
			self.opaque ? "YES" : "NO",
			theAutoResizeMaskStr,
			self.layer,
			self.value,
			self.angle,
			self.radius,
			self.cartesianPoint.x,
			self.cartesianPoint.y];
}

#pragma mark -
#pragma mark NSCoding Protocol methods
static CGFloat decodeDoubleWithDefault( NSCoder * aCoder, NSString * aKey, CGFloat aDefault )
{
	NSNumber		* theValue = [aCoder decodeObjectForKey:aKey];
	return theValue != nil ? theValue.doubleValue : aDefault;
}
static BOOL decodeBooleanWithDefault( NSCoder * aCoder, NSString * aKey, BOOL aDefault )
{
	NSNumber		* theValue = [aCoder decodeObjectForKey:aKey];
	return theValue != nil ? theValue.boolValue : aDefault;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if( (self = [super initWithCoder:aDecoder]) != nil )
	{
			self.radius = decodeDoubleWithDefault( aDecoder, kRadiusCodingKey, kDefaultRadius );
			self.linearSensitivity = decodeDoubleWithDefault( aDecoder, kLinearSensitivityCodingKey, kDefaultLinearSensitivity );
			self.minimumValue = decodeDoubleWithDefault( aDecoder, kMinimumValueCodingKey, kDefaultMinimumValue );
			self.maximumValue = decodeDoubleWithDefault( aDecoder, kMaximumValueCodingKey, kDefaultMaximumValue );
			self.minimumDomain = decodeDoubleWithDefault( aDecoder, kMinimumDomainCodingKey, kDefaultMinimumDomain );
			self.maximumDomain = decodeDoubleWithDefault( aDecoder, kMaximumDomainCodingKey, kDefaultMaximumDomain );
			self.thumbTint = kDefaultThumbTint;
			self.continuous = decodeBooleanWithDefault( aDecoder, kContinuousCodingKey, kDefaultContinuousValue );
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)anEncoder
{
		[anEncoder encodeDouble:self.radius forKey:kRadiusCodingKey];
		[anEncoder encodeDouble:self.linearSensitivity forKey:kLinearSensitivityCodingKey];
		[anEncoder encodeDouble:self.minimumValue forKey:kMinimumValueCodingKey];
		[anEncoder encodeDouble:self.maximumValue forKey:kMaximumValueCodingKey];
		[anEncoder encodeDouble:self.minimumDomain forKey:kMinimumDomainCodingKey];
		[anEncoder encodeDouble:self.maximumDomain forKey:kMaximumDomainCodingKey];
		[anEncoder encodeBool:self.continuous forKey:kContinuousCodingKey];
}

#pragma mark -
#pragma mark UIControl

- (UIControlEvents)allControlEvents { return UIControlEventValueChanged; }

- (BOOL)beginTrackingWithTouch:(UITouch *)aTouch withEvent:(UIEvent *)anEvent
{
	CGPoint			thePoint = [aTouch locationInView:self];
	self.touchDownYLocation = thePoint.y;
	self.touchDownAngle = self.angle;
	self.location = thePoint;
	if( self.isContinuous )
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self setNeedsDisplay];
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)aTouch withEvent:(UIEvent *)anEvent
{
	self.location = [aTouch locationInView:self];
	if( self.isContinuous )
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self setNeedsDisplay];
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)aTouch withEvent:(UIEvent *)anEvent
{
	self.location = [aTouch locationInView:self];
	[self sendActionsForControlEvents:UIControlEventValueChanged];
	[self setNeedsDisplay];
}

- (void)cancelTrackingWithEvent:(UIEvent *)anEvent { [self setNeedsDisplay]; }

#pragma mark -
#pragma mark UIView

- (void)setFrame:(CGRect)aRect
{
	[self deleteThumbCache];
	[self deleteBodyCache];
	[super setFrame:aRect];
}

- (void)setBounds:(CGRect)aRect
{
	[self deleteThumbCache];
	[self deleteBodyCache];
	[super setBounds:aRect];
}

- (CGSize)sizeThatFits:(CGSize)aSize
{
	return aSize.width < aSize.height
	? CGSizeMake(aSize.width, aSize.width)
	: CGSizeMake(aSize.height, aSize.height);
}

- (void)drawRect:(CGRect)aRect
{
	if( self.isOpaque )
	{
		[self.backgroundColor set];
		UIRectFill( aRect );
	}
	
	if( self.state & UIControlStateHighlighted )
		[self.cachedBodyImage drawInRect:self.bounds];
	else
		[self.cachedHilightedBodyImage drawInRect:self.bounds];
	//	[self drawBodyRect:aRect];
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
	CGRect		theResult = self.bounds;
	CGRect		theBounds = theResult;
	theResult.size.height = floorf( CGRectGetHeight(theResult) * 0.95);
	theResult.size.width = floorf( CGRectGetWidth(theResult) * 0.95);
	theResult.origin.y += ceilf( CGRectGetHeight(theResult) * 0.01);
	theResult.origin.x += ceilf( ( CGRectGetWidth(theBounds) - CGRectGetWidth(theResult)) * 0.5);
	theResult = shrinkRect(theResult, CGSizeMake(1.0,1.0));
	return largestSquareWithinRect(theResult);
}

- (CGRect)thumbRect
{
	CGRect			theBounds = self.bodyRect;
	CGFloat			theBoundsSize = MIN(CGRectGetWidth(theBounds), CGRectGetHeight(theBounds));
	CGFloat			theThumbDiam = theBoundsSize * 0.25;
	if( theThumbDiam < 5.0 )
		theThumbDiam = 5.0;
	if( theThumbDiam > theBoundsSize * 0.5 )
		theThumbDiam = theBoundsSize * 0.5;
	
	
	CGFloat			theThumbRadius = theThumbDiam/2.0;
	CGRect			theThumbBounds = CGRectMake( -theThumbRadius, -theThumbRadius, theThumbDiam, theThumbDiam );
	return shrinkRect(theThumbBounds, CGSizeMake(-1.0,-1.0) );
}

static CGGradientRef shadowBodyGradient( CGColorSpaceRef aColorSpace )
{
	CGFloat			theLocations[] = { 0.0, 0.3, 0.6, 1.0 };
	CGFloat			theComponents[sizeof(theLocations)/sizeof(*theLocations)*4] = { 0.0, 0.0, 0.0, 0.25,  // 0
		0.0, 0.0, 0.0, 0.125, // 1
		0.0, 0.0, 0.0, 0.0225, // 1
		0.0, 0.0, 0.0, 0.0 }; // 2
	return CGGradientCreateWithColorComponents( aColorSpace, theComponents, theLocations, sizeof(theLocations)/sizeof(*theLocations) );
}

static CGGradientRef hilightBodyGradient( CGColorSpaceRef aColorSpace, BOOL aHilighted )
{
	CGFloat			theLocations[] = { 0.0, 0.3, 0.6, 1.0 };
	CGFloat			theModifier = aHilighted ? 1.0 : 0.33;
	CGFloat			theComponents[sizeof(theLocations)/sizeof(*theLocations)*4] = { 1.0, 1.0, 1.0, 0.0225,  // 0
		1.0, 1.0, 1.0, 0.33 * theModifier, // 1
		1.0, 1.0, 1.0, 0.0225, // 1
		1.0, 1.0, 1.0, 0.0 }; // 2
	return CGGradientCreateWithColorComponents( aColorSpace, theComponents, theLocations, sizeof(theLocations)/sizeof(*theLocations) );
}

- (BOOL)drawBodyInRect:(CGRect)aRect hilighted:(BOOL)aHilighted
{
	CGContextRef	theContext = UIGraphicsGetCurrentContext();
	CGContextSaveGState( theContext );
	
	CGFloat			theStartRadius = CGRectGetHeight( aRect )*0.50;
	CGPoint			theStartCenter = CGPointMake( CGRectGetMidX(aRect), CGRectGetMidY(aRect) ),
	theShadowEndCenter = CGPointMake(theStartCenter.x, theStartCenter.y-0.05*theStartRadius ),
	theHilightEndCenter = CGPointMake(theStartCenter.x, theStartCenter.y+0.1*theStartRadius );
	CGColorSpaceRef	theColorSpace = CGColorGetColorSpace(self.backgroundColor.CGColor);
	CGFloat			theBodyShadowColorComponents[] = { 0.0, 0.0, 0.0, 0.2 };
	
	if( aHilighted )
		CGContextSetRGBFillColor( theContext, 0.9, 0.9, 0.9, 1.0);
	else
		CGContextSetRGBFillColor( theContext, 0.8, 0.8, 0.8, 1.0);
	
	CGContextSetRGBStrokeColor(theContext, 0.75, 0.75, 0.75, 1.0);
	CGContextRef	theBaseContext = UIGraphicsGetCurrentContext();
	CGContextSaveGState( theBaseContext );
	CGContextSetShadowWithColor( theBaseContext, CGSizeMake(0.0, theStartRadius*0.05), 2.0, CGColorCreate( theColorSpace, theBodyShadowColorComponents ) );
	CGContextFillEllipseInRect( theBaseContext, aRect );
	CGContextRestoreGState( theBaseContext );
	
	CGContextDrawRadialGradient( theContext, hilightBodyGradient(theColorSpace,aHilighted), theStartCenter, theStartRadius, theHilightEndCenter, theStartRadius*0.85, 0.0 );
	CGContextDrawRadialGradient( theContext, shadowBodyGradient(theColorSpace), theStartCenter, theStartRadius, theShadowEndCenter, theStartRadius*0.85, 0.0 );
	
	CGContextSetAllowsAntialiasing( theContext, YES );
	CGContextSetRGBStrokeColor( theContext, 0.5, 0.5, 0.5, 1.0 );
	CGContextStrokeEllipseInRect( theContext, aRect );
	
	CGContextRestoreGState( theContext );
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

@synthesize 	touchDownAngle,
touchDownYLocation;

- (CGPoint)location
{
	CGRect			theBounds = self.bodyRect,
	theThumbRect = self.thumbRect;
	return mapPoint( self.constrainedCartesianPoint, CGRectMake(-1.0, -1.0, 2.0, 2.0), shrinkRect(theBounds, CGSizeMake(CGRectGetWidth(theThumbRect)*0.68,CGRectGetHeight(theThumbRect)*0.68) ) );
}

- (void)setLocation:(CGPoint)aPoint
{
		CGRect		theBounds = self.bodyRect,
		theThumbRect = self.thumbRect;
		self.cartesianPoint = mapPoint(aPoint, shrinkRect(theBounds, CGSizeMake(CGRectGetWidth(theThumbRect)*0.68,CGRectGetHeight(theThumbRect)*0.68) ), CGRectMake(-1.0, -1.0, 2.0, 2.0 ) );
}

- (UIImage *)cachedBodyImage
{
	if( cachedBodyImage == nil )
	{
		CGRect		theBounds = self.bounds;
		UIGraphicsBeginImageContext( theBounds.size );
		if( [self drawBodyInRect:self.bodyRect hilighted:NO] )
			cachedBodyImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedBodyImage = self.cachedHilightedBodyImage;
		UIGraphicsEndImageContext();
	}
	return cachedBodyImage;
}

- (UIImage *)cachedHilightedBodyImage
{
	if( cachedHilightedBodyImage == nil )
	{
		CGRect		theBounds = self.bounds;
		UIGraphicsBeginImageContext( theBounds.size );
		if( [self drawBodyInRect:self.bodyRect hilighted:YES] )
			cachedHilightedBodyImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedHilightedBodyImage = self.cachedBodyImage;
		UIGraphicsEndImageContext();
	}
	return cachedHilightedBodyImage;
}

- (UIImage *)cachedThumbImage
{
	if( cachedThumbImage == nil )
	{
		CGRect		theThumbRect = self.thumbRect;
		theThumbRect.origin.x = 0;
		theThumbRect.origin.y = 0;
		UIGraphicsBeginImageContext( theThumbRect.size );
		if( [self drawThumbInRect:theThumbRect hilighted:NO] )
			cachedThumbImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedThumbImage = self.cachedHilightedThumbImage;
		UIGraphicsEndImageContext();
	}
	return cachedThumbImage;
}

- (UIImage *)cachedHilightedThumbImage
{
	if( cachedHilightedThumbImage == nil )
	{
		CGRect		theThumbRect = self.thumbRect;
		theThumbRect.origin.x = 0;
		theThumbRect.origin.y = 0;
		UIGraphicsBeginImageContext( theThumbRect.size );
		if( [self drawThumbInRect:theThumbRect hilighted:YES] )
			cachedHilightedThumbImage = UIGraphicsGetImageFromCurrentImageContext();
		else
			cachedHilightedThumbImage = self.cachedThumbImage;
		UIGraphicsEndImageContext();
	}
	return cachedHilightedThumbImage;
}

@end
