//
//  TagFilterButton.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-14.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagFilterButton.h"

@interface TagFilterButton ()

@property (nonatomic) UIView *selectView;

@end

@implementation TagFilterButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.lineBreakMode   = NSLineBreakByTruncatingTail;

        CGFloat width = frame.size.width - 60;
        CGFloat x = (frame.size.width - width) / 2;

		self.selectView                        = [[UIView alloc] initWithFrame:CGRectMake(x, frame.size.height - 6, width, 6)];
		self.selectView.backgroundColor        = [UIColor clearColor];
		self.selectView.userInteractionEnabled = NO;

		[self addSubview:self.selectView];
    }

    return self;
}

#pragma mark -
#pragma mark Public properties

- (void)setTitleBackgroundColor:(UIColor *)titleBackgroundColor {
    if (_titleBackgroundColor != titleBackgroundColor) {
        _titleBackgroundColor = titleBackgroundColor;

        [self.titleLabel setBackgroundColor:_titleBackgroundColor];
    }
}

- (void)setTitleFont:(UIFont *)titleFont {
    if (_titleFont != titleFont) {
        _titleFont = titleFont;

        [self.titleLabel setFont:_titleFont];
    }
}

- (void)setTitleColor:(UIColor *)titleColor {
    if (_titleColor != titleColor) {
        _titleColor = titleColor;

        [self setTitleColor:_titleColor forState:UIControlStateNormal];
    }
}

- (void)setSelectedTitleColor:(UIColor *)selectedTitleColor {
    if (_selectedTitleColor != selectedTitleColor) {
        _selectedTitleColor = selectedTitleColor;
    }
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    if (_selectedColor != selectedColor) {
        _selectedColor = selectedColor;
    }
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];

	UIColor *titleColor = selected ? self.selectedTitleColor : self.titleColor;
	UIColor *selectColor = selected ? self.selectedColor : [UIColor clearColor];

	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:0.2 animations: ^{
	    [weakSelf setTitleColor:titleColor forState:UIControlStateNormal];
	    weakSelf.selectView.backgroundColor = selectColor;
	}];
}

@end
