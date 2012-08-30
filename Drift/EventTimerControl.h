//
//  EventTimerControl.h
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

typedef enum : NSInteger {
    EventTimerTransformingNone = 0,
    EventTimerTransformingStartHandStart,
    EventTimerTransformingStartHandStop,
    EventTimerTransformingStopHandStart,
    EventTimerTransformingStopHandStop
} EventTimerTransformingEnum;

@interface EventTimerControl : UIControl

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *nowDate;
@property (nonatomic) NSDate *stopDate;

@property (nonatomic) EventTimerTransformingEnum isTransforming;

- (void)startWithDate:(NSDate *)date;
- (void)stopWithDate:(NSDate *)date;

@end
