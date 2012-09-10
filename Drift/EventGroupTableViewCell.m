//
//  EventGroupTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroupTableViewCell.h"

@interface EventGroupTableViewCell ()

@end

@implementation EventGroupTableViewCell

#pragma mark -
#pragma mark Lifecycle

- (void)awakeFromNib {
    self.weekDay.transform = CGAffineTransformMakeRotation (-3.14/2);
}

@end
