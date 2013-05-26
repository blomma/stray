// 
//  UIScrollView+AIPulling.m
//  stray
//  
//  Created by Mikael Hultgren on 2013-03-10.
//  Copyright 2013 Artsoftheinsane. All rights reserved.
// 

#import "UIScrollView+AIPulling.h"

#import <objc/runtime.h>
#import <FontAwesomeKit.h>

@interface AIPullingView ()

@property (nonatomic, copy) void (^actionHandler)(AIPullingState state, AIPullingState previousState, CGFloat height);

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *stateIcon;

@property (nonatomic, readwrite) AIPullingState state;

@property (nonatomic, weak) UIScrollView *scrollView;

@end

#pragma mark -
#pragma mark - AIPulling

@implementation AIPullingView

@synthesize actionHandler;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // default styling values
        self.textColor        = [UIColor whiteColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.state            = AIPullingStateInitial;
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
        self.stateIcon.font            = [FontAwesomeKit fontWithSize:30];
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

    if (self.state == AIPullingStatePullingClose) {
        self.backgroundColor = self.backgroundColorForCloseState;
        self.titleLabel.text = @"Release to Close...";
        self.stateIcon.text  = FAKIconRemove;

    } else if (self.state == AIPullingStatePullingAdd) {
        self.backgroundColor = self.backgroundColorForAddState;
        self.titleLabel.text = @"Release to Add...";
        self.stateIcon.text  = FAKIconOk;

    } else if (self.state == AIPullingStatePulling) {
        CGFloat alphaHeight = self.addingHeight == 0 ? self.closingHeight : self.addingHeight;
        alphaHeight += self.scrollView.contentInset.top;

        CGFloat alpha = (fabsf(self.scrollView.contentOffset.y) / alphaHeight);

        self.backgroundColor = self.addingHeight == 0 ? [self.backgroundColorForCloseState colorWithAlphaComponent:alpha] : [self.backgroundColorForAddState colorWithAlphaComponent:alpha];
        self.titleLabel.text = self.addingHeight == 0 ? @"Pull to Close..." : @"Pull to Add...";
        self.stateIcon.text  = @"";

    } else if (self.state == AIPullingStateAction) {
        self.titleLabel.text = @"";
        self.stateIcon.text  = @"";

    } else if (self.state == AIPullingStateInitial) {
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
        if (self.state == AIPullingStateAction && self.state != AIPullingStateInitial && fabsf(contentOffset.y) <= fabsf(self.scrollView.contentInset.top)) {
            self.state = AIPullingStateInitial;
        } else if (self.state != AIPullingStateInitial) {
            self.state = AIPullingStateAction;
        }

        return;
    }

    if (contentOffset.y >= -self.scrollView.contentInset.top) {
        if (self.state != AIPullingStateInitial) {
            self.state = AIPullingStateInitial;
        }

        return;
    }

    CGFloat heightForCloseState  = self.closingHeight + self.scrollView.contentInset.top;
    CGFloat heightForAddState    = self.addingHeight + self.scrollView.contentInset.top;
    CGFloat heightForCancelState = self.addingHeight == 0 ? heightForCloseState : heightForAddState;

    if (fabsf(contentOffset.y) < heightForCancelState) {
        self.state = AIPullingStatePulling;
    } else if (fabsf(contentOffset.y) > heightForCloseState) {
        self.state = AIPullingStatePullingClose;
    } else if (fabsf(contentOffset.y) >= heightForAddState && self.addingHeight != 0) {
        self.state = AIPullingStatePullingAdd;
    }
}

#pragma mark -
#pragma mark - Public properties

- (void)setState:(AIPullingState)state {
    AIPullingState previousState = _state;
    _state = state;

    [self setNeedsLayout];

    if (self.actionHandler) {
        self.actionHandler(state, previousState, self.scrollView.contentOffset.y + self.scrollView.contentInset.top);
    }
}

@end

#pragma mark -
#pragma mark - UIScrollView (AIPulling)

@implementation UITableView (AIPulling)

- (void)addPullingWithActionHandler:(void (^)(AIPullingState state, AIPullingState previousState, CGFloat height))actionHandler  {
    if (!self.pullingView) {
        AIPullingView *view = [[AIPullingView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 0)];
        view.actionHandler = actionHandler;
        view.scrollView    = self;

        [self addSubview:view];
        self.pullingView = view;

        [self addObserver:self.pullingView
               forKeyPath:@"contentOffset"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    }
}

- (void)disablePulling {
    if (self.pullingView) {
        [self removeObserver:self.pullingView
                  forKeyPath:@"contentOffset"];

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

- (void)setPullingView:(AIPullingView *)pullingView {
    objc_setAssociatedObject(self, (__bridge const void *)(@"kPullingViewKey"), pullingView, OBJC_ASSOCIATION_ASSIGN);
}

- (AIPullingView *)pullingView {
    return objc_getAssociatedObject(self, (__bridge const void *)(@"kPullingViewKey"));
}

@end
