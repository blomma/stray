//
//  TimerFaceView.h
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerFaceControl : UIControl

@property(nonatomic) NSDate *startDate;
@property(nonatomic) NSDate *nowDate;
@property(nonatomic) NSDate *stopDate;

- (void)startWithDate:(NSDate *)date;
- (void)stopWithDate:(NSDate *)date;

@end
