//
//  SegueSlideLeft.m
//
//  Copyright (c) 2012 Alex Moffat. All rights reserved.
//
//  Segue that slides the destintion up from the bottom
//  to cover the source.

#import <QuartzCore/QuartzCore.h>
#import "SegueSlideUp.h"

@implementation SegueSlideUp

- (CATransform3D)initialDestinationImageTransformation:(CGRect)sourceBounds {
    return CATransform3DMakeTranslation(0, sourceBounds.size.height, 0);
}

- (CABasicAnimation *)destinationTranslation {
    CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    translation.toValue = [NSNumber numberWithFloat:0];
    return translation;
}

@end