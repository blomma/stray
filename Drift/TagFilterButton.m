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

        self.selectView = UIView.new;
        self.selectView.userInteractionEnabled = NO;

        [self addSubview:self.selectView];

        [self.selectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@6);
            make.left.equalTo(self.mas_left).offset(30);
            make.right.equalTo(self.mas_right).offset(-30);
            make.bottom.equalTo(self.mas_bottom);
        }];
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
