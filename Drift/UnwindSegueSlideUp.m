//
//  UnwindSegueSlideUp.m
//  Drift
//
//  Created by Mikael Hultgren on 2013-05-10.
//  Copyright (c) 2013 Artsoftheinsane. All rights reserved.
//

#import "UnwindSegueSlideUp.h"

@implementation UnwindSegueSlideUp

- (CAAnimation *)srcTranslation:(CGRect)bounds {
    CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    translation.toValue = [NSNumber numberWithFloat:-bounds.size.height];

    return translation;
}

@end