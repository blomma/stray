//
//  Utility.h
//  Drift
//
//  Created by Mikael Hultgren on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (NSString *)boolToString:(BOOL)value;
+ (CGFloat)decodeDoubleWithDefault:(NSCoder *)coder key:(NSString *)key defaultValue:(CGFloat)defaultValue;
+ (CGFloat)decodeBooleanWithDefault:(NSCoder *)coder key:(NSString *)key defaultValue:(BOOL)defaultValue;
+ (CGFloat)constrainValue:(CGFloat)value min:(CGFloat)min max:(CGFloat)max;
+ (CGFloat)wrapValue:(CGFloat)value min:(CGFloat)min max:(CGFloat)max;
+ (CGFloat)mapValue:(CGFloat)value minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue minR:(CGFloat)minR maxR:(CGFloat)maxR;
+ (CGPoint)mapPoint:(const CGPoint)value rangeV:(const CGRect)rangeV rangeR:(const CGRect)rangeR;
+ (CGRect)shrinkRect:(const CGRect)rect size:(CGSize)size;
+ (CGRect)largestSquareWithinRect:(const CGRect)rect;

@end
