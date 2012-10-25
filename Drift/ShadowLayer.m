//
//  ShadowLayer.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-25.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "ShadowLayer.h"

@implementation ShadowLayer

#pragma mark -
#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        self.masksToBounds = YES;
        self.needsDisplayOnBoundsChange = YES;

        [self setShadowColor:[[UIColor colorWithWhite:0 alpha:1] CGColor]];
        [self setShadowOffset:CGSizeMake(0.0f, 0.0f)];
        [self setShadowOpacity:1.0f];
        [self setShadowRadius:5];

//        [self setFillRule:kCAFillRuleEvenOdd];

        self.shadowMask = ShadowMaskAll;
    }

    return self;
}

- (void)layoutSublayers {
    [super layoutSublayers];

    CGFloat top = (self.shadowMask & ShadowMaskTop ? 0 : self.shadowRadius);
    CGFloat bottom = (self.shadowMask & ShadowMaskBottom ? 0 : self.shadowRadius);
    CGFloat left = (self.shadowMask & ShadowMaskLeft ? 0 : self.shadowRadius);
    CGFloat right = (self.shadowMask & ShadowMaskRight ? 0 : self.shadowRadius);

    CGRect shadowFrame = CGRectMake(self.bounds.origin.x - left,
                                   self.bounds.origin.y - top,
                                   self.bounds.size.width + left + right,
                                   self.bounds.size.height + top + bottom);

    self.shadowPath = [UIBezierPath bezierPathWithRect:shadowFrame].CGPath;
}

#pragma mark -
#pragma mark Public properties

- (void)setShadowMask:(ShadowMask)shadowMask {
    _shadowMask = shadowMask;
    [self setNeedsLayout];
}

- (void)setShadowColor:(CGColorRef)shadowColor {
    [super setShadowColor:shadowColor];
    [self setNeedsLayout];
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
    [super setShadowOpacity:shadowOpacity];
    [self setNeedsLayout];
}

- (void)setShadowOffset:(CGSize)shadowOffset {
    [super setShadowOffset:shadowOffset];
    [self setNeedsLayout];
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
    [super setShadowRadius:shadowRadius];
    [self setNeedsLayout];
}

@end
