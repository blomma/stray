//
//  NoHitCAShapeLayer.m
//  Drift
//
//  Created by Mikael Hultgren on 8/26/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NoHitCAShapeLayer.h"

@implementation NoHitCAShapeLayer

#pragma mark -
#pragma mark CAShapeLayer

- (BOOL)containsPoint:(CGPoint)point {
	return NO;
}

@end
