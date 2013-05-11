//
//  SegueSlideDown.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SegueSlideDown.h"

@implementation SegueSlideDown

- (CATransform3D)initialDestinationImageTransformation:(CGRect)sourceBounds {
    return CATransform3DMakeTranslation(0, -sourceBounds.size.height, 0);
}

- (CABasicAnimation *)destinationTranslation {
    CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    translation.toValue = [NSNumber numberWithFloat:0];

    return translation;
}

@end