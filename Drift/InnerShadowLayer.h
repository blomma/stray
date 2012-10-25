//
//  InnerShadowLayer.h
//  Drift
//
//  Created by Mikael Hultgren on 10/24/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoHitCAShapeLayer.h"

typedef enum {
    InnerShadowMaskNone       = 0,
    InnerShadowMaskTop        = 1 << 1,
    InnerShadowMaskBottom     = 1 << 2,
    InnerShadowMaskLeft       = 1 << 3,
    InnerShadowMaskRight      = 1 << 4,
    InnerShadowMaskVertical   = InnerShadowMaskTop | InnerShadowMaskBottom,
    InnerShadowMaskHorizontal = InnerShadowMaskLeft | InnerShadowMaskRight,
    InnerShadowMaskAll        = InnerShadowMaskVertical | InnerShadowMaskHorizontal
} InnerShadowMask;

//
// Ideas from Matt Wilding:
// http://stackoverflow.com/questions/4431292/inner-shadow-effect-on-uiview-layer
//
@interface InnerShadowLayer : NoHitCAShapeLayer

@property (nonatomic) InnerShadowMask shadowMask;

@end
