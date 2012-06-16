//
//  Utility.m
//  Drift
//
//  Created by Mikael Hultgren on 5/24/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Utility.h"

@implementation Utility

#pragma mark -
#pragma mark Conversion methods

+ (NSString *)boolToString:(BOOL)value 
{
	return value ? @"TRUE" : @"FALSE";
}

#pragma mark -
#pragma mark NSCoding Protocol methods

+ (CGFloat)decodeDoubleWithDefault:(NSCoder *)coder key:(NSString *)key defaultValue:(CGFloat)defaultValue 
{
	NSNumber *value = [coder decodeObjectForKey:key];
	
	return value != nil
		? value.doubleValue
		: defaultValue;
}

+ (CGFloat)decodeBooleanWithDefault:(NSCoder *)coder key:(NSString *)key defaultValue:(BOOL)defaultValue 
{
	NSNumber *value = [coder decodeObjectForKey:key];
	
	return value != nil
		? value.boolValue
		: defaultValue;
}

#pragma mark -
#pragma mark Calculation methods

+ (CGFloat)constrainValue:(CGFloat)value min:(CGFloat)min max:(CGFloat)max 
{
	return value < min
		? min
		: (value > max ? max : value);
}

+ (CGFloat)wrapValue:(CGFloat)value min:(CGFloat)min max:(CGFloat)max 
{	
	CGFloat x = value-min,
			y = max-min;
	
	CGFloat r = fmodf(x,y);
	
	r = r < 0.0
		? r + y
		: r;

	return r+min;
}

+ (CGFloat)mapValue:(CGFloat)value minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue minR:(CGFloat)minR maxR:(CGFloat)maxR 
{
	return ((value-minValue)/(maxValue-minValue)) * (maxR - minR) + minR;
}

+ (CGPoint)mapPoint:(const CGPoint)value rangeV:(const CGRect)rangeV rangeR:(const CGRect)rangeR 
{	
	return CGPointMake(
					   [Utility mapValue:value.x 
								minValue:CGRectGetMinX(rangeV) 
								maxValue:CGRectGetMaxX(rangeV) 
									minR:CGRectGetMinX(rangeR) 
									maxR:CGRectGetMaxX(rangeR)],
					   [Utility mapValue:value.y 
								minValue:CGRectGetMinY(rangeV) 
								maxValue:CGRectGetMaxY(rangeV) 
									minR:CGRectGetMinY(rangeR) 
									maxR:CGRectGetMaxY(rangeR)]);
}

+ (CGRect)shrinkRect:(const CGRect)rect size:(CGSize)size 
{
	return CGRectMake(
					  CGRectGetMinX(rect)+size.width,
					  CGRectGetMinY(rect)+size.height,
					  CGRectGetWidth(rect)-2.0 * size.width,
					  CGRectGetHeight(rect)-2.0 * size.height);
}

+ (CGRect)largestSquareWithinRect:(const CGRect)rect 
{
	CGFloat	scale = MIN(CGRectGetWidth(rect), CGRectGetHeight(rect));
	
	return CGRectMake(
					  CGRectGetMinX(rect),
					  CGRectGetMinY(rect),
					  scale,
					  scale);
}

@end
