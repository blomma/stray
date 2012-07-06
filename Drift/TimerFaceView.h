//
//  TimerFaceView.h
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerFaceView : UIControl

@property(nonatomic) NSDate *startTime;

- (void)updateForElapsedSecondsIntoHour:(double)seconds;

@end
