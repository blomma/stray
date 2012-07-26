//
//  TimerArchiveEventCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/1/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "TimerArchiveEventCell.h"

@interface TimerArchiveEventCell ()

@end

@implementation TimerArchiveEventCell

@synthesize nameLabel = _nameLabel;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
	}
    return self;	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
