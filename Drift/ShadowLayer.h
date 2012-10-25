//
//  ShadowLayer.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-25.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NoHitCAShapeLayer.h"

typedef enum {
    ShadowMaskNone       = 0,
    ShadowMaskTop        = 1 << 1,
    ShadowMaskBottom     = 1 << 2,
    ShadowMaskLeft       = 1 << 3,
    ShadowMaskRight      = 1 << 4,
    ShadowMaskVertical   = ShadowMaskTop | ShadowMaskBottom,
    ShadowMaskHorizontal = ShadowMaskLeft | ShadowMaskRight,
    ShadowMaskAll        = ShadowMaskVertical | ShadowMaskHorizontal
} ShadowMask;

@interface ShadowLayer : NoHitCAShapeLayer

@property (nonatomic) ShadowMask shadowMask;

@end
