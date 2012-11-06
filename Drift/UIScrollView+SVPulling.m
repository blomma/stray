//
// UIScrollView+SVPulling.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//

#import "UIScrollView+SVPulling.h"
#import <objc/runtime.h>

@interface SVPullingView ()

@property (nonatomic, copy) void (^pullingActionHandler)(SVPullingState state, CGFloat height);

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic, readwrite) SVPullingState state;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic) CGFloat originalTopInset;

@end

#pragma mark - SVPulling
@implementation SVPullingView

@synthesize pullingActionHandler;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // default styling values
        self.textColor = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state = SVPullingStateStopped;

        // Default values;
        self.addingHeight = 60;
        self.closingHeight = 120;

        // Default colors
        self.backgroundColorForAddState = [UIColor colorWithRed:0.510f green:0.784f blue:0.431f alpha:1];
        self.backgroundColorForCloseState = [UIColor colorWithRed:0.843f green:0.306f blue:0.314f alpha:1];
    }

    return self;
}

- (void)layoutSubviews {
    DLog(NSStringFromSelector(_cmd));
    self.frame = CGRectMake(0, self.scrollView.contentOffset.y, self.superview.bounds.size.width, fabsf(self.scrollView.contentOffset.y) + self.originalTopInset);

    if (self.state == SVPullingStateTriggeredClose) {
        self.backgroundColor = self.backgroundColorForCloseState;
        self.titleLabel.text = @"Release to Close...";
    } else if (self.state == SVPullingStateTriggeredAdd) {
        self.backgroundColor = self.backgroundColorForAddState;
        self.titleLabel.text = @"Release to Add...";
    } else if (self.state == SVPullingStateStopped){
        CGFloat alphaHeight = self.addingHeight == 0 ? self.closingHeight : self.addingHeight;
        alphaHeight += self.originalTopInset;
        
        CGFloat alpha = (fabsf(self.scrollView.contentOffset.y) / alphaHeight);
        self.backgroundColor = self.addingHeight == 0 ? [self.backgroundColorForCloseState colorWithAlphaComponent:alpha] : [self.backgroundColorForAddState colorWithAlphaComponent:alpha];
        self.titleLabel.text = self.addingHeight == 0 ? @"Pull to Close..." : @"Pull to Add...";
    } else if (self.state == SVPullingStateTrigger) {
        self.titleLabel.text = @"";
        [UIView animateWithDuration:0.2 animations:^{
            self.frame = CGRectMake(0, 0, self.superview.bounds.size.width, 0);
            self.backgroundColor = [UIColor clearColor];
        }];
    }
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (self.scrollView.decelerating) {
        if (self.state != SVPullingStateTrigger) {
            self.state = SVPullingStateTrigger;
        }

        return;
    }

    if (contentOffset.y > 0) {
        return;
    }

    CGFloat heightForCloseState = self.closingHeight + self.originalTopInset;
    CGFloat heightForAddState = self.addingHeight + self.originalTopInset;
    CGFloat heightForCancelState = self.addingHeight == 0 ? heightForCloseState : heightForAddState;

    if(fabsf(contentOffset.y) < heightForCancelState) {
        self.state = SVPullingStateStopped;
    } else if(fabsf(contentOffset.y) > heightForCloseState) {
        self.state = SVPullingStateTriggeredClose;
    } else if(fabsf(self.scrollView.contentOffset.y) >= heightForAddState) {
        self.state = SVPullingStateTriggeredAdd;
    }
}

#pragma mark - Getters

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.bounds.size.width, 20)];
        _titleLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = self.textColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;

        [self addSubview:_titleLabel];
    }

    return _titleLabel;
}

#pragma mark -

- (void)setState:(SVPullingState)state {
    SVPullingState previousState = _state;
    _state = state;

    switch (state) {
        case SVPullingStateStopped:
            [self setNeedsLayout];
            break;

        case SVPullingStateTriggeredAdd:
            [self setNeedsLayout];
            break;

        case SVPullingStateTriggeredClose:
            [self setNeedsLayout];
            break;

        case SVPullingStateTrigger:
            [self setNeedsLayout];
            if (pullingActionHandler && (previousState == SVPullingStateTriggeredAdd || previousState == SVPullingStateTriggeredClose)) {
                pullingActionHandler(previousState, self.scrollView.contentOffset.y);
            }
    }
}

@end

#pragma mark - UIScrollView (SVPulling)

@implementation UIScrollView (SVPulling)

- (void)addPullingWithActionHandler:(void (^)(SVPullingState state, CGFloat height))actionHandler {
    if (!self.pullingView) {
        SVPullingView *view = [[SVPullingView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 0)];
        view.pullingActionHandler = actionHandler;
        view.scrollView = self;
        view.originalTopInset = self.contentInset.top;
        view.clipsToBounds = YES;

        [self addSubview:view];

        self.pullingView = view;

        [self addObserver:self.pullingView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)disablePulling {
    if (self.pullingView) {
        [self removeObserver:self.pullingView forKeyPath:@"contentOffset"];
        self.pullingView.pullingActionHandler = nil;
        self.pullingView.scrollView = nil;

        [self.pullingView.titleLabel removeFromSuperview];
        self.pullingView.titleLabel = nil;

        [self.pullingView removeFromSuperview];
        self.pullingView = nil;
    }
}

- (void)setPullingView:(SVPullingView *)pullingView {
    objc_setAssociatedObject(self, (__bridge const void *)(@"kPullingViewKey"), pullingView, OBJC_ASSOCIATION_ASSIGN);
}

- (SVPullingView *)pullingView {
    return objc_getAssociatedObject(self, (__bridge const void *)(@"kPullingViewKey"));
}

@end