//
//  EventTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 9/7/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventTableViewCell.h"

@implementation EventTableViewCell

- (IBAction)touchUpInsideTagButton:(UIButton *)sender forEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(cell:tappedTagButton:forEvent:)]) {
        [self.delegate cell:self tappedTagButton:sender forEvent:event];
    }
}

@end
