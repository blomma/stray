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
        self.selectView = [[UIView alloc] initWithFrame:CGRectMake(30, CGRectGetMaxY(self.bounds) - 4, self.bounds.size.width - 60, 4)];
        self.selectView.backgroundColor = [UIColor clearColor];
        self.selectView.userInteractionEnabled = NO;
    
        [self addSubview:self.selectView];
    }

    [UIView animateWithDuration:0.2 animations:^{
        self.selectView.backgroundColor = selected ? [UIColor colorWithRed:0.427f green:0.784f blue:0.992f alpha:0.8] : [UIColor clearColor];
    }];
}

@end
