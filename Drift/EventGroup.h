//
//  EventGroup.h
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

@interface EventGroup : NSObject

@property (nonatomic, readonly) NSMutableArray *events;
@property (nonatomic, readonly) NSDate *groupDate;
@property (nonatomic, readonly) NSDateComponents *timeActiveComponents;

@property (nonatomic, readonly) Event *activeEvent;

@property (nonatomic, readonly) NSUInteger count;

- (id)initWithDate:(NSDate *)groupDate;
- (BOOL)containsEvent:(Event *)event;

- (NSSet *)addEvent:(Event *)event;
- (NSSet *)removeEvent:(Event *)event;
- (NSSet *)updateEvent:(Event *)event;

- (BOOL)isValidForEvent:(Event *)event;

- (NSComparisonResult)compare:(id)element;

@end
