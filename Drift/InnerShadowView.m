//
//  InnerShadowView.m
//  Drift
//
//  Created by Mikael Hultgren on 10/24/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "InnerShadowView.h"

@interface InnerShadowView ()

@property (nonatomic) InnerShadowLayer* innerShadowLayer;

@end

@implementation InnerShadowView

#pragma mark -
#pragma mark Lifecycle

- (void)_init {
    // add as sublayer so that self.backgroundColor will work nicely
    self.innerShadowLayer = [InnerShadowLayer layer];
    
    self.innerShadowLayer.actions = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNull null], @"position",
                                 [NSNull null], @"bounds",
                                 [NSNull null], @"contents",
                                 [NSNull null], @"shadowColor",
                                 [NSNull null], @"shadowOpacity",
                                 [NSNull null], @"shadowOffset",
                                 [NSNull null], @"shadowRadius",
                                 nil];
    
    [self.layer addSublayer:self.innerShadowLayer];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.innerShadowLayer.frame = self.layer.bounds;
}

#pragma mark -
#pragma mark Public properties

- (InnerShadowMask)shadowMask {
    return self.innerShadowLayer.shadowMask;
}

- (void)setShadowMask:(InnerShadowMask)shadowMask {
    self.innerShadowLayer.shadowMask = shadowMask;
}

- (UIColor *)shadowColor {
    return [UIColor colorWithCGColor:self.innerShadowLayer.shadowColor];
}

- (void)setShadowColor:(UIColor *)shadowColor {
    self.innerShadowLayer.shadowColor = shadowColor.CGColor;
}

- (CGFloat)shadowOpacity {
    return self.innerShadowLayer.shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
    self.innerShadowLayer.shadowOpacity = shadowOpacity;
}

- (CGSize)shadowOffset {
    return self.innerShadowLayer.shadowOffset;
}

- (void)setShadowOffset:(CGSize)shadowOffset {
    self.innerShadowLayer.shadowOffset = shadowOffset;
}

- (CGFloat)shadowRadius {
    return self.innerShadowLayer.shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
    self.innerShadowLayer.shadowRadius = shadowRadius;
}

@end
