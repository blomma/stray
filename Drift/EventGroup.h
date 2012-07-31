//
//  EventGroup.h
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

@interface EventGroup : NSObject

@property (nonatomic) NSDate *groupDate;
@property (nonatomic, readonly) NSArray *groupEvents;
@property (nonatomic, readonly) NSDateComponents *groupRunningTime;

- (void)addEvent:(Event *)event;
- (void)removeEvent:(Event *)event;

- (NSComparisonResult)compare:(id)element;

@end
