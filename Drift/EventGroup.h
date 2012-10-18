//
//  EventGroup.h
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "Tag.h"

@interface EventGroup : NSObject

@property (nonatomic, readonly) NSDate *groupDate;
@property (nonatomic, readonly) NSDateComponents *timeActiveComponents;

@property (nonatomic, readonly) NSUInteger count;

@property (nonatomic) Tag *filter;
@property (nonatomic, readonly) NSArray *filteredEvents;

- (id)initWithDate:(NSDate *)groupDate;
- (BOOL)containsEvent:(Event *)event;

- (void)addEvent:(Event *)event;
- (void)removeEvent:(Event *)event;
- (void)updateEvent:(Event *)event;

- (BOOL)isValidForEvent:(Event *)event;

- (NSComparisonResult)compare:(id)element;

@end
