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

@property (nonatomic) NSSet *filters;
@property (nonatomic) NSUInteger count;

- (id)initWithEvents:(NSArray *)events withFilters:(NSSet *)filters;

- (void)addEvent:(Event *)event;
- (void)removeEvent:(Event *)event;
- (void)updateEvent:(Event *)event;

- (id)objectAtIndex:(NSUInteger)index;

@end
