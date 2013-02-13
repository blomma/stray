//
//  State.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-15.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Event.h"

@interface State : NSObject

+ (State *)instance;

@property (nonatomic, weak, readonly) Event *activeEvent;
@property (nonatomic, weak) Event *selectedEvent;

@property (nonatomic) NSMutableSet *eventsGroupedByDateFilter;
@property (nonatomic) NSMutableSet *eventsGroupedByStartDateFilter;

- (void)persistState;

@end
