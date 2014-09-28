//
//  TagTableViewCellBackView.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-27.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagTableViewCellBackView.h"

@implementation TagTableViewCellBackView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    // bottom line
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.267f alpha:0.1f].CGColor);
    CGContextFillRect (context, CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1));

    // top line
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.267f alpha:0.1f].CGColor);
    CGContextFillRect (context, CGRectMake(0, 0, self.bounds.size.width, 1));
}

@end
