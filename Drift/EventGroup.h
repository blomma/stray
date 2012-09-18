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
@property (nonatomic, readonly) NSString *GUID;
@property (nonatomic, readonly) BOOL isActive;
@property (nonatomic, readonly) NSArray *changes;

- (id)initWithDate:(NSDate *)groupDate;
- (BOOL)containsEvent:(Event *)event;

- (void)addEvent:(Event *)event;
- (void)removeEvent:(Event *)event;
- (void)updateEvent:(Event *)event;

- (BOOL)canContainDate:(NSDate *)date;
- (BOOL)isValidForEvent:(Event *)event;

- (Event *)activeEvent;

- (NSUInteger)count;

- (NSComparisonResult)compare:(id)element;

@end
