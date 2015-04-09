//
//  State.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-11-15.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface State : NSObject

+ (State *)instance;

@property (nonatomic, readonly) NSMutableSet *eventsGroupedByDateFilter;
@property (nonatomic, readonly) NSMutableSet *eventsGroupedByStartDateFilter;
@property (nonatomic) NSString *selectedEventGUID;

- (void)persistState;

@end
