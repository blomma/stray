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

@property (nonatomic) Tag *filter;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) EventGroup *activeEventGroup;

- (id)init;
- (id)initWithEvents:(NSArray *)events;
- (id)initWithEvents:(NSArray *)events filter:(Tag *)tag;

- (NSArray *)addEvent:(Event *)event;
- (NSArray *)removeEvent:(Event *)event;
- (NSArray *)updateEvent:(Event *)event;

- (EventGroup *)eventGroupAtIndex:(NSUInteger)index;

@end
