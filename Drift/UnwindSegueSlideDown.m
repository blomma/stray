//
//  SegueSlideLeft.m
//
//  Copyright (c) 2012 Alex Moffat. All rights reserved.
//
//  Slide the source down to reveal the destination.

#import <QuartzCore/QuartzCore.h>
#import "UnwindSegueSlideDown.h"

@implementation UnwindSegueSlideDown

- (CAAnimation *)srcTranslation:(CGRect)bounds {
    CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    translation.toValue = [NSNumber numberWithFloat:(float)bounds.size.height];

    return translation;
}

@end