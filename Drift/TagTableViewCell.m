//
//  TagTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagTableViewCell.h"
#import "NoHitCAShapeLayer.h"

@implementation TagTableViewCell

#pragma mark -
#pragma mark Lifecycle

- (void)awakeFromNib {
    NoHitCAShapeLayer *dashLayer = [NoHitCAShapeLayer layer];
    dashLayer.frame           = CGRectMake(self.tagNameTextField.frame.origin.x - 10, self.tagNameTextField.frame.origin.y + 33, self.tagNameTextField.frame.size.width + 20, 2);
    dashLayer.fillColor       = [UIColor clearColor].CGColor;
    dashLayer.strokeColor     = [UIColor colorWithWhite:0.267f alpha:0.8f].CGColor;
    dashLayer.lineWidth       = 2.0f;
    dashLayer.lineJoin        = kCALineJoinRound;
    dashLayer.lineDashPattern = @[@10, @5];

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, self.tagNameTextField.frame.size.width + 20, 0);

    [dashLayer setPath:path];
    CGPathRelease(path);

    [self.backView.layer insertSublayer:dashLayer below:self.tagNameTextField.layer];
}

- (void)prepareForReuse {
    [self marked:NO withAnimation:NO];
    
    self.leading.constant = 0;
}

#pragma mark -
#pragma mark Public methods

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

    UIColor *backgroundColor = marked ? [UIColor colorWithWhite:0.251f alpha:1.000] : [UIColor clearColor];

    if (animation) {
        CABasicAnimation *backgroundAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
        backgroundAnimation.fromValue = (id)self.rightSelected.backgroundColor.CGColor;
        backgroundAnimation.toValue   = (id)backgroundColor.CGColor;
        backgroundAnimation.duration  = 0.4;
        [self.rightSelected.layer addAnimation:backgroundAnimation forKey:@"backgroundColor"];
    }
    
    self.rightSelected.layer.backgroundColor = backgroundColor.CGColor;
}

#pragma mark -
#pragma mark Public properties

- (void)setTagTitle:(NSString *)title {
    self.tagNameTextField.text = title ? [title uppercaseString] : @"";
    self.tagName.text = title ? [title uppercaseString] : @"Swipe ⇢ to name";
    self.tagName.textColor = title ? [UIColor colorWithWhite:0.267f alpha:1.0f] : [UIColor colorWithWhite:0.267f alpha:0.4f];
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
