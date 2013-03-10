// 
//  UIScrollView+AIPulling.h
//  stray
//  
//  Created by Mikael Hultgren on 2013-03-10.
//  Copyright 2013 Artsoftheinsane. All rights reserved.
// 

#import <UIKit/UIKit.h>

@class AIPullingView;

typedef NS_ENUM (NSUInteger, AIPullingState) {
    AIPullingStatePulling = 0,
    AIPullingStatePullingAdd,
    AIPullingStatePullingClose,
    AIPullingStateAction,
    AIPullingStateInitial
};

@interface UITableView (AIPulling)

- (void)addPullingWithActionHandler:(void (^)(AIPullingState state, AIPullingState previousState, CGFloat height))actionHandler;
- (void)disablePulling;

@property (nonatomic, readonly) AIPullingView *pullingView;

@end

@interface AIPullingView : UIView

@property (nonatomic) UIColor *textColor;
@property (nonatomic, readonly) AIPullingState state;

@property (nonatomic) UIColor *backgroundColorForAddState;
@property (nonatomic) UIColor *backgroundColorForCloseState;

@property (nonatomic) CGFloat addingHeight;
@property (nonatomic) CGFloat closingHeight;

@end
