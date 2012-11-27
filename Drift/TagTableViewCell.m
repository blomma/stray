//
//  TagTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagTableViewCell.h"

@interface TagTableViewCell ()

@property (nonatomic) NoHitCAShapeLayer *dashLayer;
@property (nonatomic) CALayer *selectLayer;
@property (nonatomic) CALayer *cellRightSeparatorLayer;
@property (nonatomic) CALayer *cellBottomSeparatorLayer;
@property (nonatomic) CALayer *cellTopSeparatorLayer;

@end

@implementation TagTableViewCell

- (void)drawRect:(CGRect)rect {
    if (!self.dashLayer) {
        self.dashLayer = [NoHitCAShapeLayer layer];
        self.dashLayer.frame           = CGRectMake(self.nameTextField.frame.origin.x - 10, self.nameTextField.frame.origin.y + 33, self.nameTextField.frame.size.width + 20, 2);
        self.dashLayer.fillColor       = [UIColor clearColor].CGColor;
        self.dashLayer.strokeColor     = [UIColor colorWithWhite:0.267 alpha:0.8f].CGColor;
        self.dashLayer.lineWidth       = 2.0f;
        self.dashLayer.lineJoin        = kCALineJoinRound;
        self.dashLayer.lineDashPattern = @[@10, @5];

        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, 0, 0);
        CGPathAddLineToPoint(path, NULL, self.nameTextField.frame.size.width + 20, 0);

        [self.dashLayer setPath:path];
        CGPathRelease(path);

        [self.backView.layer insertSublayer:self.dashLayer below:self.nameTextField.layer];
    }

    // Show a marker when sliding the cell
    if (!self.cellRightSeparatorLayer) {
        self.cellRightSeparatorLayer = [CALayer layer];
        self.cellRightSeparatorLayer.frame = CGRectMake(-10, 0, 10, self.layer.bounds.size.height);
        self.cellRightSeparatorLayer.backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.0f].CGColor;

        [self.frontView.layer addSublayer:self.cellRightSeparatorLayer];
    }

    if (!self.cellBottomSeparatorLayer) {
        self.cellBottomSeparatorLayer = [CALayer layer];
        self.cellBottomSeparatorLayer.frame = CGRectMake(0, self.layer.bounds.size.height - 1, self.layer.bounds.size.width, 1);
        self.cellBottomSeparatorLayer.backgroundColor = [UIColor colorWithWhite:0.267 alpha:0.05f].CGColor;

        [self.backView.layer addSublayer:self.cellBottomSeparatorLayer];
    }

    if (!self.cellTopSeparatorLayer) {
        self.cellTopSeparatorLayer = [CALayer layer];
        self.cellTopSeparatorLayer.frame = CGRectMake(0, 0, self.layer.bounds.size.width, 1);
        self.cellTopSeparatorLayer.backgroundColor = [UIColor colorWithWhite:0.267 alpha:0.05f].CGColor;

        [self.backView.layer addSublayer:self.cellTopSeparatorLayer];
    }
}

- (void)prepareForReuse {
    [self marked:NO withAnimation:NO];

    if (self.selectLayer) {
        self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;
    }
}

- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(cell:tappedDeleteButton:forEvent:)]) {
        [self.delegate cell:self tappedDeleteButton:sender forEvent:event];
    }
}

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation {
    if (self.marked == marked) {
        return;
    }

    self.marked = marked;

    if (!self.selectLayer) {
        self.selectLayer                 = [CALayer layer];
        self.selectLayer.frame           = CGRectMake(self.layer.bounds.size.width - 10, 0, 10, self.layer.bounds.size.height);
        self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;
        [self.frontView.layer addSublayer:self.selectLayer];
    }

    UIColor *backgroundColor = marked ? [UIColor colorWithWhite:0.251f alpha:1.000] : [UIColor clearColor];

    if (animation) {
        CABasicAnimation *backgroundAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        backgroundAnimation.fromValue = (id)self.selectLayer.backgroundColor;
        backgroundAnimation.toValue   = (id)backgroundColor.CGColor;
        backgroundAnimation.duration  = 0.4;
        [self.selectLayer addAnimation:backgroundAnimation forKey:@"backgroundColor"];
    }

    self.selectLayer.backgroundColor = backgroundColor.CGColor;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.delegate respondsToSelector:@selector(cell:didChangeTagName:)]) {
        [self.delegate cell:self didChangeTagName:[textField.text copy]];
    }
}

@end
