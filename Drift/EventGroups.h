//
//  EventGroups.h
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventGroup.h"
#import "Tag.h"

@interface EventGroups : NSObject

@property (nonatomic) Tag *filter;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) EventGroup *activeEventGroup;

- (id)init;
- (id)initWithEvents:(NSArray *)events;
- (id)initWithEvents:(NSArray *)events filter:(Tag *)tag;

- (NSSet *)addEvent:(Event *)event;
- (NSSet *)removeEvent:(Event *)event;
- (NSSet *)updateEvent:(Event *)event;

- (EventGroup *)eventGroupAtIndex:(NSUInteger)index;

@end
