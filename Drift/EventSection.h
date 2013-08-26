//
//  EventGroupTableViewCell.h
//  Drift
//
//  Created by Mikael Hultgren on 7/28/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

@interface EventSection : UITableViewHeaderFooterView

@property (nonatomic) UILabel *hour;
@property (nonatomic) UILabel *minute;
@property (nonatomic) UILabel *day;
@property (nonatomic) UILabel *weekDay;
@property (nonatomic) UILabel *month;
@property (nonatomic) UILabel *year;

@end
