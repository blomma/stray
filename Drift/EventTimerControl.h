//
//  EventTimerControl.h
//  Drift
//
//  Created by Mikael Hultgren on 6/16/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

typedef NS_ENUM(NSInteger, EventTimerTransformingEnum) {
    EventTimerNotTransforming,
    EventTimerStartDateTransformingStart,
    EventTimerStartDateTransformingStop,
    EventTimerNowDateTransformingStart,
    EventTimerNowDateTransformingStop
};

@interface EventTimerControl : UIControl

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *nowDate;

@property (nonatomic) EventTimerTransformingEnum transforming;

- (void)initWithStartDate:(NSDate *)startDate andStopDate:(NSDate *)stopDate;
- (void)paus;
- (void)stop;
- (void)reset;

@end