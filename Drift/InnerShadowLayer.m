//
//  InnerShadowLayer.m
//  Drift
//
//  Created by Mikael Hultgren on 10/24/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "InnerShadowLayer.h"

@implementation InnerShadowLayer

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

        [self setFillRule:kCAFillRuleEvenOdd];
        
        self.shadowMask = InnerShadowMaskAll;
    }

    return self;
}

- (void)layoutSublayers {
    [super layoutSublayers];
    
    CGFloat top = (self.shadowMask & InnerShadowMaskTop ? self.shadowRadius : 0);
    CGFloat bottom = (self.shadowMask & InnerShadowMaskBottom ? self.shadowRadius : 0);
    CGFloat left = (self.shadowMask & InnerShadowMaskLeft ? self.shadowRadius : 0);
    CGFloat right = (self.shadowMask & InnerShadowMaskRight ? self.shadowRadius : 0);
    
    CGRect largerRect = CGRectMake(self.bounds.origin.x - left,
                                   self.bounds.origin.y - top,
                                   self.bounds.size.width + left + right,
                                   self.bounds.size.height + top + bottom);
    
    // Create the larger rectangle path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, largerRect);

    // Add the inner path so it's subtracted from the outer path.
    CGPathAddPath(path, NULL, [UIBezierPath bezierPathWithRect:self.bounds].CGPath);
    CGPathCloseSubpath(path);
    
    [self setPath:path];
    CGPathRelease(path);
}

#pragma mark -
#pragma mark Public properties

- (void)setShadowMask:(InnerShadowMask)shadowMask {
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
