//
//  TimerFaceView.h
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerFaceControl : UIControl

@property(nonatomic, readonly) NSDate *startDate;
@property(nonatomic, readonly) NSDate *nowDate;
@property(nonatomic, readonly) NSDate *stopDate;

- (void)startWithDate:(NSDate *)date;
- (void)stopWithDate:(NSDate *)date;

@end
