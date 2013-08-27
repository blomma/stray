//
//  TagTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "NoHitCAShapeLayer.h"
#import "TagTableViewCell.h"
#import <FontAwesomeKit.h>

@interface TagTableViewCell ()

@property (nonatomic) CALayer *selectLayer;

@end

@implementation TagTableViewCell

#pragma mark -
#pragma mark Lifecycle

- (void)awakeFromNib {
	CALayer *cellRightSeparatorLayer = [CALayer layer];
	cellRightSeparatorLayer.frame           = CGRectMake(-10, 0, 10, self.layer.bounds.size.height);
	cellRightSeparatorLayer.backgroundColor = [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:1.0f].CGColor;

	[self.frontView.layer addSublayer:cellRightSeparatorLayer];

	NoHitCAShapeLayer *dashLayer = [NoHitCAShapeLayer layer];
	dashLayer.frame           = CGRectMake(self.tagNameTextField.frame.origin.x - 10, self.tagNameTextField.frame.origin.y + 33, self.tagNameTextField.frame.size.width + 20, 2);
	dashLayer.fillColor       = [UIColor clearColor].CGColor;
	dashLayer.strokeColor     = [UIColor colorWithWhite:0.267 alpha:0.8f].CGColor;
	dashLayer.lineWidth       = 2.0f;
	dashLayer.lineJoin        = kCALineJoinRound;
	dashLayer.lineDashPattern = @[@10, @5];

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	CGPathAddLineToPoint(path, NULL, self.tagNameTextField.frame.size.width + 20, 0);

	[dashLayer setPath:path];
	CGPathRelease(path);

	self.deleteButton.titleLabel.font = [UIFont fontWithName:@"FontAwesome" size:30];
	self.deleteButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.deleteButton.titleLabel.backgroundColor = [UIColor clearColor];

	self.deleteButton.backgroundColor = [UIColor clearColor];

	UIColor *color = [UIColor colorWithRed:0.318f green:0.318f blue:0.318f alpha:1];
	UIColor *colorHighlighted = [UIColor colorWithRed:0.158f green:0.158f blue:0.158f alpha:1];
	[self.deleteButton setTitleColor:color forState:UIControlStateNormal];
	[self.deleteButton setTitleColor:colorHighlighted forState:UIControlStateHighlighted];

	[self.deleteButton setTitle:FAKIconRemoveSign forState:UIControlStateNormal];

	[self.backView.layer insertSublayer:dashLayer below:self.tagNameTextField.layer];

	self.selectLayer                 = [CALayer layer];
	self.selectLayer.frame           = CGRectMake(self.layer.bounds.size.width - 10, 0, 10, self.layer.bounds.size.height);
	self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;

	[self.frontView.layer addSublayer:self.selectLayer];
}

- (void)prepareForReuse {
	[self marked:NO withAnimation:NO];

	if (self.selectLayer)
		self.selectLayer.backgroundColor = [UIColor clearColor].CGColor;
}

#pragma mark -
#pragma mark Public methods

- (IBAction)touchUpInsideDeleteButton:(UIButton *)sender forEvent:(UIEvent *)event {
	if (self.didDeleteHandler)
		self.didDeleteHandler();
}

- (void)marked:(BOOL)marked withAnimation:(BOOL)animation {
	if (self.marked == marked)
		return;

	self.marked = marked;

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
#pragma mark Public properties

- (void)setTagTitle:(NSString *)title {
	self.tagNameTextField.text = title ? [title uppercaseString] : @"";
	self.tagName.text = title ? [title uppercaseString] : @"Swipe ⇢ to name";
	self.tagName.textColor = title ? [UIColor colorWithWhite:0.267 alpha:1.000] : [UIColor colorWithWhite:0.267 alpha:0.4];
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
	if (self.didEditHandler)
		self.didEditHandler(textField.text);
}

@end
