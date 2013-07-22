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
	EventTimerNowDateTransformingStart,
	EventTimerNowDateTransformingStop,
	EventTimerNotTransforming
} EventTimerTransformingEnum;

@interface EventTimerControl : UIControl

@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *nowDate;

@property (nonatomic) EventTimerTransformingEnum transforming;

- (void)startWithEvent:(Event *)event;
- (void)paus;
- (void)stop;
- (void)reset;

@end
