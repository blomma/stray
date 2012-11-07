//
//  Events.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-10-27.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

@interface Events : NSObject

@property (nonatomic, readonly) NSMutableOrderedSet *filteredEvents;

@property (nonatomic) NSSet *filters;

@property (nonatomic, readonly) NSUInteger count;

- (id)init;
- (id)initWithEvents:(NSArray *)events;

- (void)removeObject:(id)object;

@end
