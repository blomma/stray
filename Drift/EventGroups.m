//
//  EventGroups.m
//  Drift
//
//  Created by Mikael Hultgren on 7/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroups.h"
#import "NSDate+Utilities.h"
#import "Tag.h"
#import "Change.h"
#import "DataManager.h"

@interface EventGroups ()

@property (nonatomic) NSMutableArray *events;
@property (nonatomic) NSMutableArray *eventGroups;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic, readwrite) EventGroup *activeEventGroup;
@property (nonatomic) BOOL activeEventGroupIsInvalid;

@end

@implementation EventGroups

#pragma mark -
#pragma mark Lifecycle

- (id)init {
	return [self initWithEvents:[NSArray array]];
}

- (id)initWithEvents:(NSArray *)events {
	return [self initWithEvents:events filter:nil];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithEvents:(NSArray *)events filter:(Tag *)tag {
    self = [super init];
	if (self) {
        self.events      = [[NSMutableArray alloc] initWithArray:events];
        self.eventGroups = [NSMutableArray array];
        self.calendar    = [NSCalendar currentCalendar];

        [self filterOnTag:tag];
	}

	return self;
}

#pragma mark -
#pragma mark Public properties

- (NSUInteger)count {
	return self.eventGroups.count;
}

- (EventGroup *)activeEventGroup {
    if (self.activeEventGroupIsInvalid) {
        [self updateActiveEventGroup];
    }

    return _activeEventGroup;
}

#pragma mark -
#pragma mark Public methods

- (NSSet *)addEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet set];

    if (![self.events containsObject:event]) {
        [self.events addObject:event];
    }

    if (self.filter && ![event.inTag isEqual:self.filter]) {
        return changes;
    }

	NSDate *startDate = event.startDate;
	NSDate *stopDate  = event.stopDate;

	// Is the event running, if so set the stopDate to now
	if ([event isActive]) {
		stopDate = [NSDate date];
	}

	// Calculate how many seconds this event spans
	unsigned int unitFlags = NSSecondCalendarUnit;
	NSDateComponents *eventSecondsComponent = [self.calendar components:unitFlags
                                                               fromDate:startDate
                                                                 toDate:stopDate
                                                                options:0];

	NSDateComponents *totalSecondsComponent = [[NSDateComponents alloc] init];
	totalSecondsComponent.second = 0;

	// Loop over it until there are no more future time left in it
	while (eventSecondsComponent.second >= 0) {
		startDate = [self.calendar dateByAddingComponents:totalSecondsComponent
                                                   toDate:event.startDate
                                                  options:0];

		// Find a EventGroup for this startDate
		EventGroup *eventGroup;
        NSUInteger index = [self indexForGroupDate:startDate];

        if (index == NSNotFound) {
            eventGroup = [[EventGroup alloc] initWithDate:startDate];
        } else {
            eventGroup = [self.eventGroups objectAtIndex:index];
        }

		// Check if this eventGroup already has this event
		if (![eventGroup containsEvent:event]) {
			Change *change = [Change new];

			if (index == NSNotFound) {
                change.type = ChangeInsert;

                index = [self insertionIndexForGroupDate:eventGroup.groupDate];
                [self.eventGroups insertObject:eventGroup atIndex:index];
			} else {
                change.type = ChangeUpdate;
                change.index = index;
			}

            change.object = eventGroup;

            [changes unionSet:[eventGroup addEvent:event]];
			[changes addObject:change];
		}

		// We want to add the delta between the startDate day and end of startDate day
		// this only nets us enough delta to make it to the end of the day so
		// we need to add one second to this to tip it over
		NSDate *endOfDay = [startDate endOfDayWithCalendar:self.calendar];
		NSDateComponents *deltaSecondsComponent = [self.calendar components:unitFlags
                                                                   fromDate:startDate
                                                                     toDate:endOfDay
                                                                    options:0];
		deltaSecondsComponent.second += 1;

		totalSecondsComponent.second += deltaSecondsComponent.second;
		eventSecondsComponent.second -= deltaSecondsComponent.second;
	}

    // Update insert index for EventGroups
    for (Change *change in changes) {
        if ([change.type isEqualToString:ChangeInsert] && [change.object isKindOfClass:[EventGroup class]]) {
            NSUInteger i = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
                return [obj isEqual:change.object];
            }];
            change.index = i;
        }
    }

    self.activeEventGroupIsInvalid = YES;

	return changes;
}

- (NSSet *)removeEvent:(Event *)event {
    [self.events removeObject:event];

    return [self removeFromGroupsEvent:event];
}

- (NSSet *)updateEvent:(Event *)event {
    // If this event doesnt even fullfill the tag filter then we just need to remove it and be done
    if (self.filter && ![event.inTag isEqual:self.filter]) {
        return [self removeFromGroupsEvent:event];
    }

    NSMutableSet *changes = [NSMutableSet set];

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event] && [eventGroup isValidForEvent:event]) {
			Change *change = [Change new];
			change.object  = eventGroup;
			change.type  = ChangeUpdate;
            change.index = i;

            [changes unionSet:[eventGroup updateEvent:event]];
			[changes addObject:change];
		}
	}

	// Insert event into any groups that can contain it, possibly creating new groups for this
    [changes unionSet:[self addEvent:event]];

    // Next we remove the event from invalid eventGroups
    [changes unionSet:[self removeFromInvalidGroupsEvent:event]];

    self.activeEventGroupIsInvalid = YES;

	return changes;
}

- (NSSet *)filterOnTag:(Tag *)tag {
    // TODO: Need to rethink how Changes are handled, at the moment
    // it failts spectacualry when adding several events
    NSMutableSet *changes = [NSMutableSet set];

    self.filter = tag;

    for (Event *event in self.events) {
        if (tag && ![event.inTag isEqual:tag]) {
            // Remove if tag is not nill and the event is not a match
            [changes unionSet:[self removeFromGroupsEvent:event]];
        } else {
            // Readd the event, the underlying code will handle if the event already exists
            [changes unionSet:[self addEvent:event]];
        }
    }

    NSSet *minusChanges = [changes objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        Change *change = (Change *)obj;
        if ([change.type isEqualToString:ChangeUpdate]) {
            for (Change *c in changes) {
                if ([c.type isEqualToString:ChangeDelete] && [c.object isEqual:change.object] && c.index == change.index) {
                    return YES;
                }
            }
        }

        return NO;
    }];

    [changes minusSet:minusChanges];

    return changes;
}

- (EventGroup *)eventGroupAtIndex:(NSUInteger)index {
	return [self.eventGroups objectAtIndex:index];
}

#pragma mark -
#pragma mark Private methods

- (NSSet *)removeFromGroupsEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet set];
    
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event]) {
            [changes unionSet:[eventGroup removeEvent:event]];

            Change *change = [Change new];
            change.object  = eventGroup;
            change.type  = eventGroup.count > 0 ? ChangeUpdate : ChangeDelete;
            change.index = i;

            if ([change.type isEqualToString:ChangeDelete]) {
                [indexesToRemove addIndex:i];
            }

			[changes addObject:change];
		}
	}

    // Remove empty groups
    [self.eventGroups removeObjectsAtIndexes:indexesToRemove];

    self.activeEventGroupIsInvalid = YES;

	return changes;
}

- (NSSet *)removeFromInvalidGroupsEvent:(Event *)event {
    NSMutableSet *changes = [NSMutableSet set];
    NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet new];

    for (NSUInteger i = 0; i < self.eventGroups.count; i++) {
        EventGroup *eventGroup = [self.eventGroups objectAtIndex:i];

		if ([eventGroup containsEvent:event] && ![eventGroup isValidForEvent:event]) {
            [changes unionSet:[eventGroup removeEvent:event]];

            Change *change = [Change new];
            change.object  = eventGroup;
            change.type  = eventGroup.count > 0 ? ChangeUpdate : ChangeDelete;
            change.index = i;

            if ([change.type isEqualToString:ChangeDelete]) {
                [indexesToRemove addIndex:i];
            }

			[changes addObject:change];
		}
	}

    // Remove empty groups
    [self.eventGroups removeObjectsAtIndexes:indexesToRemove];

    self.activeEventGroupIsInvalid = YES;

	return changes;
}

- (NSUInteger)indexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        return [[(EventGroup *)obj groupDate] isEqualToDateIgnoringTime:date withCalendar:self.calendar];
    }];

    return index;
}

- (NSUInteger)insertionIndexForGroupDate:(NSDate *)date {
    NSUInteger index = [self.eventGroups indexOfObjectPassingTest:^BOOL (id obj, NSUInteger idx, BOOL * stop) {
        return [[(EventGroup *)obj groupDate] compare:date] == NSOrderedAscending;
    }];

    if (index == NSNotFound) {
        index = self.eventGroups.count;
    }
    
    return index;
}

- (void)updateActiveEventGroup {
    self.activeEventGroup = nil;
    
	if (self.eventGroups.count > 0) {
		EventGroup *eventGroup = [self.eventGroups objectAtIndex:0];
		if (eventGroup.activeEvent) {
            self.activeEventGroup = eventGroup;
		}
	}
}


@end