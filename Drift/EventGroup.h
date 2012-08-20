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
@property (nonatomic) NSDate *groupDate;
@property (nonatomic, readonly) NSDateComponents *groupTime;
@property (nonatomic, readonly) NSString *GUID;
@property (nonatomic, readonly) BOOL isRunning;

- (id)initWithDate:(NSDate *)groupDate;
- (BOOL)containsEvent:(Event *)event;

- (void)addEvent:(Event *)event;
- (void)removeEvent:(Event *)event;
- (void)updateEvent:(Event *)event;

- (BOOL)canContainDate:(NSDate *)date;
- (BOOL)canContainEvent:(Event *)event;

- (NSUInteger)count;

- (NSComparisonResult)compare:(id)element;

@end
