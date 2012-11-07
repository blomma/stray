//
//  EventTimerControl.h
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

typedef enum : NSInteger {
    EventTimerStartDateTransformingStart,
    EventTimerStartDateTransformingStop,
    EventTimerStopDateTransformingStart,
    EventTimerStopDateTransformingStop
} EventTimerTransformingEnum;

@interface EventTimerControl : UIControl

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *nowDate;
@property (nonatomic) NSDate *stopDate;

@property (nonatomic) EventTimerTransformingEnum isTransforming;

- (void)startWithEvent:(Event *)event;
- (void)stop;
- (void)reset;

@end
