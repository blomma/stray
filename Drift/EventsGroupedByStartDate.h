//
//  EventsGroupedByStartDate.h
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"

@interface EventsGroupedByStartDate : NSObject

@property (nonatomic) NSSet *filters;

- (id)initWithEvents:(NSArray *)events withFilters:(NSSet *)filters;

- (void)addEvent:(Event *)event;
- (void)removeEvent:(Event *)event;
- (void)updateEvent:(Event *)event;

@property (nonatomic, readonly) NSUInteger filteredEventGroupCount;

- (NSIndexPath *)indexPathOfFilteredEvent:(Event *)event;
- (id)filteredEventAtIndexPath:(NSIndexPath *)indexPath;
- (id)filteredEventGroupAtIndex:(NSUInteger)index;

@end
