//
//  TagButton.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-21.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TagButton.h"

#import <FontAwesomeKit.h>

@implementation TagButton

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    if (title) {
        self.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:12];
        title = [title uppercaseString];
    } else {
        self.titleLabel.font = [FontAwesomeKit fontWithSize:20];
        title = FAKIconTag;
    }

    [super setTitle:title forState:state];
}

@end
