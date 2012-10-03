//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "Event.h"
#import "EventViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSManagedObject+ActiveRecord.h"
#import "TagViewController.h"
#import "Tag.h"
#import "DataManager.h"
#import "Change.h"

@interface EventViewController ()

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSDateComponents *previousNowComponents;

@end

@implementation EventViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    [self reset];

    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];

    self.calendar = [NSCalendar currentCalendar];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(dataModelDidSave:)
	                                             name:kDataManagerDidSaveNotification
	                                           object:[DataManager instance]];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"startDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"nowDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"stopDate"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];

	[self.eventTimerControl addObserver:self
	                         forKeyPath:@"isTransforming"
	                            options:NSKeyValueObservingOptionNew
	                            context:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    Event *event = [DataManager instance].state.inEvent;
    
    if ([event isActive]) {
        [self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
    } else {
        [self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
    }

	if (event) {
        [self.eventTimerControl startWithEvent:event];

        NSString *tagName = event.inTag ? event.inTag.name : @"";
        [self.tag setTitle:tagName forState:UIControlStateNormal];

        if (![event isActive]) {
            [self animateStopEvent];
        }
	} else {
        [self reset];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    Event *event = [[DataManager instance] state].inEvent;

    TagViewController *tagViewController = [segue destinationViewController];
    tagViewController.event = event;
}

#pragma mark -
#pragma mark Public methods

- (IBAction)toggleEvent:(id)sender {
	NSDate *now = [NSDate date];

    Event *event = [DataManager instance].state.inEvent;

	if ([event isActive]) {
		[TestFlight passCheckpoint:@"STOP EVENT"];

		event.stopDate = now;

        [self.eventTimerControl stop];

		// Toggle button to start state
		[self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];

        [self animateStopEvent];
	} else {
		[TestFlight passCheckpoint:@"START EVENT"];

        [self reset];

        event = [Event create];
		event.startDate = now;

        [DataManager instance].state.inEvent = event;

        [self.eventTimerControl startWithEvent:event];

		// Toggle button to stop state
		[self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];

        [self animateStartEvent];
	}

    [[CoreDataManager instance] saveContext];
}

#pragma mark -
#pragma mark Private methods

- (void)reset {
    [self.eventTimerControl reset];

    [self.tag setTitle:@"" forState:UIControlStateNormal];

    self.eventStartTime.text  = @"";
    self.eventStartDay.text   = @"";
    self.eventStartYear.text  = @"";
    self.eventStartMonth.text = @"";

    self.eventTimeHours.text = @"00";
    self.eventTimeMinutes.text = @"00";

    self.eventStopTime.text  = @"";
    self.eventStopDay.text   = @"";
    self.eventStopYear.text  = @"";
    self.eventStopMonth.text = @"";
}

- (void)updateStartLabelWithDate:(NSDate *)date {
    if (date) {
        static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
        NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];

        self.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
        self.eventStartDay.text   = [NSString stringWithFormat:@"%02d", components.day];
        self.eventStartYear.text  = [NSString stringWithFormat:@"%04d", components.year];
        self.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    }
}

- (void)updateEventTimeWithDate:(NSDate *)date {
    Event *event = [DataManager instance].state.inEvent;

    if (date && event) {
        static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit;

        NSDateComponents *components = [self.calendar components:unitFlags fromDate:event.startDate toDate:date options:0];

        if (components.hour != self.previousNowComponents.hour
            || components.minute != self.previousNowComponents.minute) {
            self.eventTimeHours.text   = [NSString stringWithFormat:@"%02d", components.hour];
            self.eventTimeMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];
            self.previousNowComponents = components;
        }
    }
}

- (void)updateStopLabelWithDate:(NSDate *)date {
    if (date) {
        static NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
        NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];

        self.eventStopTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
        self.eventStopDay.text   = [NSString stringWithFormat:@"%02d", components.day];
        self.eventStopYear.text  = [NSString stringWithFormat:@"%04d", components.year];
        self.eventStopMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    }
}

- (void)animateStartEvent {
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.eventStartDay.alpha = 1;
        self.eventStartMonth.alpha = 1;
        self.eventStartTime.alpha = 1;
        self.eventStartYear.alpha = 1;

        self.eventStopDay.alpha = 0.2;
        self.eventStopMonth.alpha = 0.2;
        self.eventStopTime.alpha = 0.2;
        self.eventStopYear.alpha = 0.2;
    } completion:nil];
}

- (void)animateStopEvent {
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.eventStartDay.alpha = 0.2;
        self.eventStartMonth.alpha = 0.2;
        self.eventStartTime.alpha = 0.2;
        self.eventStartYear.alpha = 0.2;

        self.eventStopDay.alpha = 1;
        self.eventStopMonth.alpha = 1;
        self.eventStopTime.alpha = 1;
        self.eventStopYear.alpha = 1;
    } completion:nil];
}

- (void)animateEventTransforming:(EventTimerTransformingEnum)eventTimerTransformingEnum {
    Event *event = [DataManager instance].state.inEvent;

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGFloat eventStartAlpha, eventStopAlpha, eventTimeAlpha;
        switch (eventTimerTransformingEnum) {
            case EventTimerStartDateTransformingStart:
                eventStartAlpha = 1;
                eventStopAlpha = 0.2f;
                eventTimeAlpha = 0.2f;
                break;
            case EventTimerStartDateTransformingStop:
                eventStartAlpha = event.isActive ? 1 : 0.2f;
                eventStopAlpha = event.isActive ? 0.2f : 1;
                eventTimeAlpha = 1;
                break;
            case EventTimerStopDateTransformingStart:
                eventStartAlpha = 0.2f;
                eventStopAlpha = 1;
                eventTimeAlpha = 0.2f;
                break;
            case EventTimerStopDateTransformingStop:
                eventStartAlpha = event.isActive ? 1 : 0.2f;
                eventStopAlpha = event.isActive ? 0.2f : 1;
                eventTimeAlpha = 1;
                break;
            default:
                break;
        }

        self.eventStartDay.alpha = eventStartAlpha;
        self.eventStartMonth.alpha = eventStartAlpha;
        self.eventStartTime.alpha = eventStartAlpha;
        self.eventStartYear.alpha = eventStartAlpha;

        self.eventStopDay.alpha = eventStopAlpha;
        self.eventStopMonth.alpha = eventStopAlpha;
        self.eventStopTime.alpha = eventStopAlpha;
        self.eventStopYear.alpha = eventStopAlpha;

        self.eventTimeHours.alpha = eventTimeAlpha;
        self.eventTimeMinutes.alpha = eventTimeAlpha;
    } completion:nil];
}

- (void)dataModelDidSave:(NSNotification *)note {
    Event *event = [DataManager instance].state.inEvent;

	NSSet *eventChangeObjects = [[note userInfo] objectForKey:kEventChangesKey];
    NSArray *deletedEvents = [[eventChangeObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        Change *change = (Change *)obj;
        return [change.type isEqualToString:ChangeDelete] && [change.object isEqual:event];
    }] allObjects];

    DLog(@"eventChangeObjects %@", eventChangeObjects);
    DLog(@"deletedEvents %@", deletedEvents);

    if (deletedEvents.count > 0) {
        [DataManager instance].state.inEvent = nil;

        [self reset];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    Event *event = [DataManager instance].state.inEvent;

	if ([keyPath isEqualToString:@"startDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        event.startDate = date;

		[self updateStartLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"nowDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

		[self updateEventTimeWithDate:date];
	} else if ([keyPath isEqualToString:@"stopDate"]) {
		NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        event.stopDate = date;

		[self updateStopLabelWithDate:date];
	} else if ([keyPath isEqualToString:@"isTransforming"]) {
        EventTimerTransformingEnum eventTimerTransformingEnum = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        [self animateEventTransforming:eventTimerTransformingEnum];

        if (eventTimerTransformingEnum == EventTimerStartDateTransformingStop || eventTimerTransformingEnum == EventTimerStopDateTransformingStop) {
            [[CoreDataManager instance] saveContext];
        }
    }
}

@end