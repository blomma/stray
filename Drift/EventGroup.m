//
//  EventGroup.m
//  Drift
//
//  Created by Mikael Hultgren on 7/30/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventGroup.h"

#import "Tag.h"
#import "NSDate+Utilities.h"

@interface EventGroup ()

@property (nonatomic) NSMutableSet *events;
@property (nonatomic) NSMutableOrderedSet *filteredEvents;
@property (nonatomic) BOOL isFilteredEventsInvalid;

@property (nonatomic, readwrite) NSDate *groupDate;

@property (nonatomic, readwrite) NSDateComponents *filteredEventsDateComponents;
@property (nonatomic) BOOL isFilteredEventsDateComponentsInvalid;

@property (nonatomic) BOOL filteredEventsContainsActiveEvent;
@property (nonatomic) BOOL isFilteredEventsContainsActiveEventInvalid;

@end

@implementation EventGroup

- (id)init {
    return [self initWithGroupDate:nil];
}

// ==========================
// = Designated initializer =
// ==========================
- (id)initWithGroupDate:(NSDate *)groupDate {
    self = [super init];
    if (self) {
        self.groupDate = groupDate;

        self.events                  = [NSMutableSet set];
        self.filteredEvents          = [NSMutableOrderedSet orderedSet];
        self.isFilteredEventsInvalid = YES;

        self.filteredEventsDateComponents          = [[NSDateComponents alloc] init];
        self.isFilteredEventsDateComponentsInvalid = YES;
    }

    return self;
}

#pragma mark -
#pragma mark Public properties

- (NSDateComponents *)filteredEventsDateComponents {
    if (self.filteredEventsContainsActiveEvent || self.isFilteredEventsDateComponentsInvalid) {
        [self updateFilteredEventsDateComponents];
    }

    return _filteredEventsDateComponents;
}

- (BOOL)filteredEventsContainsActiveEvent {
    if (self.isFilteredEventsContainsActiveEventInvalid) {
        _filteredEventsContainsActiveEvent = NO;

        for (Event *event in self.filteredEvents) {
            if ([event isActive]) {
                _filteredEventsContainsActiveEvent = YES;
                break;
            }
        }

        self.isFilteredEventsContainsActiveEventInvalid = NO;
    }

    return _filteredEventsContainsActiveEvent;
}

- (void)setFilters:(NSSet *)filters {
    _filters                     = filters;
    self.isFilteredEventsInvalid = YES;
}

- (NSMutableOrderedSet *)filteredEvents {
    if (self.isFilteredEventsInvalid) {
        [_filteredEvents removeAllObjects];

        if (self.filters.count == 0) {
            [_filteredEvents unionSet:self.events];
        } else {
            [_filteredEvents unionSet:[self.events filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"inTag.guid in %@", self.filters]]];
        }

        [_filteredEvents sortUsingComparator:^NSComparisonResult (id obj1, id obj2) {
            return [[obj2 startDate] compare:[obj1 startDate]];
        }];

        self.isFilteredEventsInvalid               = NO;
        self.isFilteredEventsDateComponentsInvalid = YES;
    }

    return _filteredEvents;
}

#pragma mark -
#pragma mark Public methods

- (void)addEvent:(Event *)event {
    [self.events addObject:event];

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag.guid]) {
        self.isFilteredEventsInvalid                    = YES;

        if ([event isActive]) {
            self.isFilteredEventsContainsActiveEventInvalid = YES;
        }
    }
}

- (void)removeEvent:(Event *)event {
    [self.events removeObject:event];

    if (self.filters.count == 0 || [self.filters containsObject:event.inTag.guid]) {
        self.isFilteredEventsInvalid                    = YES;

        if ([event isActive]) {
            self.isFilteredEventsContainsActiveEventInvalid = YES;
        }
    }
}

- (void)updateEvent:(Event *)event {
    if (self.filters.count == 0 || [self.filters containsObject:event.inTag.guid]) {
        self.isFilteredEventsInvalid                    = YES;

        if ([event isActive]) {
            self.isFilteredEventsContainsActiveEventInvalid = YES;
        }
    }
}

#pragma mark -
#pragma mark Private methods

- (void)updateFilteredEventsDateComponents {
    static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;

    NSDate *endOfDay = [self.groupDate endOfCurrentDay];

    NSDate *deltaStart = [self.groupDate copy];
    NSDate *deltaEnd   = [self.groupDate copy];

    for (Event *event in self.filteredEvents) {
        NSDate *startDate = [event.startDate laterDate:self.groupDate];
        NSDate *stopDate  = [event isActive] ? [NSDate date] : event.stopDate;
        stopDate = [stopDate earlierDate:endOfDay];


        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:startDate
                                                              toDate:stopDate
                                                             options:NSWrapCalendarComponents];

        deltaEnd = [[NSDate calendar] dateByAddingComponents:components
                                                      toDate:deltaEnd
                                                     options:0];
    }

    self.filteredEventsDateComponents = [[NSDate calendar] components:unitFlags
                                                             fromDate:deltaStart
                                                               toDate:deltaEnd
                                                              options:0];
    self.isFilteredEventsDateComponentsInvalid = NO;
}

@end
