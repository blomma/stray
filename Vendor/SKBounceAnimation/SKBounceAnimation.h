//
//  SKBounceAnimation.h
//  SKBounceAnimation
//
//  Created by Soroush Khanlou on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SKBounceAnimation : CAKeyframeAnimation

@property (nonatomic) id fromValue;
@property (nonatomic) id byValue;
@property (nonatomic) id toValue;
@property (nonatomic) NSUInteger numberOfBounces;
@property (nonatomic) BOOL shouldOvershoot; //default YES
@property (nonatomic) BOOL shake; //if shaking, set fromValue to the furthest value, and toValue to the current value

+ (SKBounceAnimation *)animationWithKeyPath:(NSString *)keyPath;

@end
