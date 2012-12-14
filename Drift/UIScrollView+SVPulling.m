//
// UIScrollView+SVPulling.m
//
// Created by Sam Vermette on 23.04.12.
// Copyright (c) 2012 samvermette.com. All rights reserved.
//

#import "UIScrollView+SVPulling.h"

#import <objc/runtime.h>

@interface SVPullingView ()

@property (nonatomic, copy) void (^actionHandler)(SVPullingState state, SVPullingState previousState, CGFloat height);

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *stateIcon;

@property (nonatomic, readwrite) SVPullingState state;

@property (nonatomic, weak) UIScrollView *scrollView;

@end

#pragma mark -
#pragma mark - SVPulling

@implementation SVPullingView

@synthesize actionHandler;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // default styling values
        self.textColor        = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state            = SVPullingStateInitial;
        self.clipsToBounds    = YES;

        // Default values;
        self.addingHeight  = 60;
        self.closingHeight = 120;

        // Default colors
        self.backgroundColorForAddState   = [UIColor colorWithRed:0.510f green:0.784f blue:0.431f alpha:1];
        self.backgroundColorForCloseState = [UIColor colorWithRed:0.745 green:0.106 blue:0.169 alpha:1.000];

        self.titleLabel                 = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, self.bounds.size.width, 50)];
        self.titleLabel.font            = [UIFont fontWithName:@"Futura-CondensedMedium" size:17];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor       = self.textColor;
        self.titleLabel.textAlignment   = NSTextAlignmentCenter;

        [self addSubview:self.titleLabel];

        self.stateIcon                 = [[UILabel alloc] initWithFrame:CGRectMake(60, 10, 50, 50)];
        self.stateIcon.font            = [UIFont fontWithName:@"Entypo" size:60];
        self.stateIcon.backgroundColor = [UIColor clearColor];
        self.stateIcon.textColor       = self.textColor;
        self.stateIcon.textAlignment   = NSTextAlignmentCenter;

        [self addSubview:self.stateIcon];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat yDelta = MIN(fabsf(self.scrollView.contentOffset.y), self.scrollView.frame.origin.y);
    CGFloat height = fabsf(self.scrollView.contentOffset.y) + yDelta;
    CGFloat y      = -height;

    CGRect frame = CGRectMake(0, y, self.bounds.size.width, height);
    self.frame = frame;

    CGRect titleLabelFrame = self.titleLabel.frame;
    titleLabelFrame.origin.y = height / 2 - (self.titleLabel.frame.size.height / 2);
    self.titleLabel.frame    = titleLabelFrame;

    CGRect stateIconFrame = self.stateIcon.frame;
    stateIconFrame.origin.y = height / 2 - (self.stateIcon.frame.size.height / 2);
    self.stateIcon.frame    = stateIconFrame;

    if (self.state == SVPullingStatePullingClose) {
        self.backgroundColor = self.backgroundColorForCloseState;
        self.titleLabel.text = @"Release to Close...";
        self.stateIcon.text  = [NSString stringWithUTF8String:"\u274C"];

    } else if (self.state == SVPullingStatePullingAdd) {
        self.backgroundColor = self.backgroundColorForAddState;
        self.titleLabel.text = @"Release to Add...";
        self.stateIcon.text  = [NSString stringWithUTF8String:"\u2713"];

    } else if (self.state == SVPullingStatePulling) {
        CGFloat alphaHeight = self.addingHeight == 0 ? self.closingHeight : self.addingHeight;
        alphaHeight += self.scrollView.contentInset.top;

        CGFloat alpha = (fabsf(self.scrollView.contentOffset.y) / alphaHeight);

        self.backgroundColor = self.addingHeight == 0 ? [self.backgroundColorForCloseState colorWithAlphaComponent:alpha] : [self.backgroundColorForAddState colorWithAlphaComponent:alpha];
        self.titleLabel.text = self.addingHeight == 0 ? @"Pull to Close..." : @"Pull to Add...";
        self.stateIcon.text  = @"";

    } else if (self.state == SVPullingStateAction) {
        self.titleLabel.text = @"";
        self.stateIcon.text  = @"";

    } else if (self.state == SVPullingStateInitial) {
        self.backgroundColor = [UIColor clearColor];
        self.titleLabel.text = @"";
        self.stateIcon.text  = @"";
    }
}

#pragma mark -
#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    if (self.scrollView.decelerating) {
        if (self.state == SVPullingStateAction && self.state != SVPullingStateInitial && fabsf(contentOffset.y) <= fabsf(self.scrollView.contentInset.top)) {
            self.state = SVPullingStateInitial;
        } else if (self.state != SVPullingStateInitial) {
            self.state = SVPullingStateAction;
        }

        return;
    }

    if (contentOffset.y >= -self.scrollView.contentInset.top) {
        if (self.state != SVPullingStateInitial) {
            self.state = SVPullingStateInitial;
        }

        return;
    }

    CGFloat heightForCloseState  = self.closingHeight + self.scrollView.contentInset.top;
    CGFloat heightForAddState    = self.addingHeight + self.scrollView.contentInset.top;
    CGFloat heightForCancelState = self.addingHeight == 0 ? heightForCloseState : heightForAddState;

    if (fabsf(contentOffset.y) < heightForCancelState) {
        self.state = SVPullingStatePulling;
    } else if (fabsf(contentOffset.y) > heightForCloseState) {
        self.state = SVPullingStatePullingClose;
    } else if (fabsf(contentOffset.y) >= heightForAddState && self.addingHeight != 0) {
        self.state = SVPullingStatePullingAdd;
    }
}

#pragma mark -
#pragma mark - Public properties

- (void)setState:(SVPullingState)state {
    SVPullingState previousState = _state;
    _state = state;

    [self setNeedsLayout];

    if (self.actionHandler) {
        self.actionHandler(state, previousState, self.scrollView.contentOffset.y + self.scrollView.contentInset.top);
    }
}

@end

#pragma mark -
#pragma mark - UIScrollView (SVPulling)

@implementation UITableView (SVPulling)

- (void)addPullingWithActionHandler:(void (^)(SVPullingState state, SVPullingState previousState, CGFloat height))actionHandler  {
    if (!self.pullingView) {
        SVPullingView *view = [[SVPullingView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 0)];
        view.actionHandler = actionHandler;
        view.scrollView    = self;

        [self addSubview:view];
        self.pullingView = view;

        [self addObserver:self.pullingView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)disablePulling {
    if (self.pullingView) {
        [self removeObserver:self.pullingView forKeyPath:@"contentOffset"];

        self.pullingView.actionHandler = nil;
        self.pullingView.scrollView    = nil;

        [self.pullingView.titleLabel removeFromSuperview];
        self.pullingView.titleLabel = nil;

        [self.pullingView.stateIcon removeFromSuperview];
        self.pullingView.stateIcon = nil;

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