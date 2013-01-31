//
// UIScrollView+SVPulling.h
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//
//

#import <UIKit/UIKit.h>

@class SVPullingView;

typedef NS_ENUM (NSUInteger, SVPullingState) {
    SVPullingStatePulling = 0,
    SVPullingStatePullingAdd,
    SVPullingStatePullingClose,
    SVPullingStateAction,
    SVPullingStateInitial
};

@interface UITableView (SVPulling)

- (void)addPullingWithActionHandler:(void (^)(SVPullingState state, SVPullingState previousState, CGFloat height))actionHandler;
- (void)disablePulling;

@property (nonatomic, readonly) SVPullingView *pullingView;

@end

@interface SVPullingView : UIView

@property (nonatomic) UIColor *textColor;
@property (nonatomic, readonly) SVPullingState state;

@property (nonatomic) UIColor *backgroundColorForAddState;
@property (nonatomic) UIColor *backgroundColorForCloseState;

@property (nonatomic) CGFloat addingHeight;
@property (nonatomic) CGFloat closingHeight;

@end
