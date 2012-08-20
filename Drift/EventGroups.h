//
//  EventGroups.h
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroup.h"

@interface EventGroups : NSObject

- (id)init;
- (id)initWithEvents:(NSArray *)events;

- (NSArray *)addEvent:(Event *)event;
- (NSArray *)removeEvent:(Event *)event withConditionIsInvalid:(BOOL)condition;
- (NSArray *)updateEvent:(Event *)event;
- (NSArray *)updateActiveEvent;

- (NSUInteger)count;

- (EventGroup *)eventGroupAtIndex:(NSUInteger)index;
- (EventGroup *)eventGroupAtDate:(NSDate *)date;

@end
