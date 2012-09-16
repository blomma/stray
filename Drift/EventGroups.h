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

@property (nonatomic) BOOL existsActiveEventGroup;

- (id)init;
- (id)initWithEvents:(NSArray *)events;

- (NSArray *)addEvent:(Event *)event;
- (void)addEvents:(NSArray *)events;

- (NSArray *)removeEvent:(Event *)event withConditionIsInvalid:(BOOL)condition;
- (NSArray *)updateEvent:(Event *)event withConditionIsActive:(BOOL)condition;

- (NSUInteger)count;

- (NSUInteger)indexForGroupDate:(NSDate *)date;
- (EventGroup *)eventGroupAtIndex:(NSUInteger)index;
- (NSUInteger)indexForActiveEventGroup;

@end
