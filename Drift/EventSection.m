//
//  EventGroupTableViewCell.m
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventSection.h"

@implementation EventSection

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }

    return self;
}

- (void)setup {
    self.hour = [[UILabel alloc] init];
    self.hour.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:40];
    [self.contentView addSubview:self.hour];
    [self.hour mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top);
        make.left.equalTo(self.contentView.mas_left);
        make.bottom.equalTo(self.contentView.mas_bottom);
        make.height.equalTo(self.contentView.mas_height);
        make.width.greaterThanOrEqualTo(@52);
    }];
}

@end
