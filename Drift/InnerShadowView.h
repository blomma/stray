//
//  InnerShadowView.h
//  Drift
//
//  Created by Mikael Hultgren on 10/24/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "InnerShadowLayer.h"

@interface InnerShadowView : UIView

@property (nonatomic, readonly) InnerShadowLayer* innerShadowLayer;

@property (nonatomic) InnerShadowMask shadowMask;

@property (nonatomic) UIColor* shadowColor;
@property (nonatomic) CGFloat  shadowOpacity;
@property (nonatomic) CGSize   shadowOffset;
@property (nonatomic) CGFloat  shadowRadius;

@end
