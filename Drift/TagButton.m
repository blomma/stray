//
//  TagButton.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-14.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagButton.h"

@interface TagButton ()

@property (nonatomic) UIView *selectView;

@end

@implementation TagButton

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

    if (!self.selectView) {
        self.selectView                        = [[UIView alloc] initWithFrame:CGRectMake(30, CGRectGetMaxY(self.bounds) - 6, self.bounds.size.width - 60, 6)];
        self.selectView.backgroundColor        = [UIColor clearColor];
        self.selectView.userInteractionEnabled = NO;

        [self addSubview:self.selectView];
    }

    UIColor *titleColor = selected ? [UIColor colorWithWhite:0.251f alpha:1.000] : [UIColor colorWithWhite:0.392f alpha:1.000];
    UIColor *selectColor = selected ? [UIColor colorWithWhite:0.251f alpha:1.000] : [UIColor clearColor];
    [UIView animateWithDuration:0.2 animations:^{
        [self setTitleColor:titleColor forState:UIControlStateNormal];
        self.selectView.backgroundColor = selectColor;
    }];
}

@end
