//
//  EventViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 5/31/12.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "EventViewController.h"

#import "Event.h"
#import "Tag.h"
#import "TagsTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Retina4.h"
#import "PopoverView.h"
#import "State.h"
#import "GAI.h"
#import "NSDate+Utilities.h"
#import "UnwindSegueSlideDown.h"
#import <THObserversAndBinders.h>

@interface EventViewController ()

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) dispatch_queue_t backgroundQueue;

// Observer
@property (nonatomic) THObserver *startDateObserver;
@property (nonatomic) THObserver *nowDateObserver;
@property (nonatomic) THObserver *stopDateObserver;
@property (nonatomic) THObserver *isTransformingObserver;

@end

@implementation EventViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.backgroundQueue = dispatch_queue_create("com.artsoftheinsane.Stray.bgqueue", NULL);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __weak typeof(self) weakSelf = self;
    self.startDateObserver = [THObserver observerForObject:self.eventTimerControl keyPath:@"startDate" oldAndNewBlock:^(id oldValue, id newValue) {
        [State instance].selectedEvent.startDate = newValue;
        [weakSelf updateStartLabelWithDate:newValue];

        if (self.eventTimerControl.isTransforming == EventTimerNotTransforming && oldValue != [NSNull null]) {
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
        }
    }];

    self.nowDateObserver = [THObserver observerForObject:self.eventTimerControl keyPath:@"nowDate" oldAndNewBlock:^(id oldValue, id newValue) {
        [weakSelf updateEventTimeWithDate:newValue];
        [weakSelf updateStopLabelWithDate:newValue];
    }];

    self.stopDateObserver = [THObserver observerForObject:self.eventTimerControl keyPath:@"stopDate" oldAndNewBlock:^(id oldValue, id newValue) {
        [State instance].selectedEvent.stopDate = newValue;
        [weakSelf updateStopLabelWithDate:newValue];

        if (self.eventTimerControl.isTransforming == EventTimerNotTransforming && oldValue != [NSNull null]) {
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
        }
    }];

    self.isTransformingObserver = [THObserver observerForObject:self.eventTimerControl keyPath:@"isTransforming" oldAndNewBlock:^(id oldValue, id newValue) {
        EventTimerTransformingEnum isTransforming = [newValue integerValue];
        if (isTransforming != EventTimerNotTransforming) {
            [weakSelf animateEventTransforming:isTransforming];
        }

        if (self.eventTimerControl.isTransforming == EventTimerNotTransforming) {
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
        }
    }];

    if ([State instance].selectedEvent) {
        [self.eventTimerControl startWithEvent:[State instance].selectedEvent];

        if ([[State instance].selectedEvent isActive]) {
            [self.toggleStartStopButton setTitle:@"STOP"
                                        forState:UIControlStateNormal];
            [self animateStartEvent];
        } else {
            [self.toggleStartStopButton setTitle:@"START"
                                        forState:UIControlStateNormal];
            [self animateStopEvent];
        }
    } else {
        [self reset];
        [self.eventTimerControl reset];
    }

    [self.tag setTitle:[[State instance].selectedEvent.inTag.name copy]
              forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.eventTimerControl paus];

    [self.startDateObserver stopObserving];
    [self.nowDateObserver stopObserving];
    [self.stopDateObserver stopObserving];
    [self.isTransformingObserver stopObserving];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvent"]) {
        [[segue destinationViewController] setDelegate:self];
        [[segue destinationViewController] setEvent:[State instance].selectedEvent];
    } else if ([segue.identifier isEqualToString:@"segueToEventsFromEvent"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (IBAction)unwindFromSegue:(UIStoryboardSegue *)segue {
}

#pragma mark -
#pragma mark TagsTableViewControllerDelegate, EventsGroupedByStartDateViewControllerDelegate

- (void)tagsTableViewControllerDidDimiss {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)eventsGroupedByStartDateViewControllerDidDimiss {
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark -
#pragma mark Public methods

- (IBAction)showTags:(id)sender {
    if ([State instance].selectedEvent) {
        [self performSegueWithIdentifier:@"segueToTagsFromEvent"
                                  sender:self];
    }
}

- (IBAction)toggleEventTouchUpInside:(id)sender forEvent:(UIEvent *)event {
    NSDate *now = [NSDate date];

    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

    if ([[State instance].selectedEvent isActive]) {
        [State instance].selectedEvent.stopDate = now;

        [self.eventTimerControl stop];

        [self.toggleStartStopButton setTitle:@"START"
                                    forState:UIControlStateNormal];
        [self animateStopEvent];
    } else {
        tracker.sessionStart = YES;
        [tracker sendEventWithCategory:@"app_flow"
                            withAction:@"event_start"
                             withLabel:nil
                             withValue:nil];
        [self reset];

        [State instance].selectedEvent           = [Event MR_createEntity];
        [State instance].selectedEvent.startDate = now;

        [self.eventTimerControl startWithEvent:[State instance].selectedEvent];

        [self.toggleStartStopButton setTitle:@"STOP"
                                    forState:UIControlStateNormal];
        [self animateStartEvent];
    }

    [self.tag setTitle:[State instance].selectedEvent.inTag.name
              forState:UIControlStateNormal];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
}

#pragma mark -
#pragma mark Private methods

- (void)reset {
    [self.toggleStartStopButton setTitle:@"START"
                                forState:UIControlStateNormal];

    self.eventStartTime.text    = @"--:--";
    self.eventStartDay.text     = @"";
    self.eventStartYear.text    = @"";
    self.eventStartMonth.text   = @"";

    self.eventTimeHours.text    = @"00";
    self.eventTimeMinutes.text  = @"00";

    self.eventStopTime.text     = @"--:--";
    self.eventStopDay.text      = @"";
    self.eventStopYear.text     = @"";
    self.eventStopMonth.text    = @"";

    self.eventStartDay.alpha    = 1;
    self.eventStartMonth.alpha  = 1;
    self.eventStartTime.alpha   = 1;
    self.eventStartYear.alpha   = 1;

    self.eventStopDay.alpha     = 1;
    self.eventStopMonth.alpha   = 1;
    self.eventStopTime.alpha    = 1;
    self.eventStopYear.alpha    = 1;

    self.eventTimeHours.alpha   = 1;
    self.eventTimeMinutes.alpha = 1;
}

- (void)updateStartLabelWithDate:(NSDate *)date {
    if (date) {
        static NSUInteger unitFlags  = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:date];

        self.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
        self.eventStartDay.text   = [NSString stringWithFormat:@"%02d", components.day];
        self.eventStartYear.text  = [NSString stringWithFormat:@"%04d", components.year];
        self.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    }
}

- (void)updateEventTimeWithDate:(NSDate *)date {
    if (date && [State instance].selectedEvent.startDate) {
        static NSUInteger unitFlags  = NSHourCalendarUnit | NSMinuteCalendarUnit;

        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:[State instance].selectedEvent.startDate
                                                              toDate:date options:0];

        self.eventTimeHours.text   = [NSString stringWithFormat:@"%02d", components.hour];
        self.eventTimeMinutes.text = [NSString stringWithFormat:@"%02d", components.minute];
    }
}

- (void)updateStopLabelWithDate:(NSDate *)date {
    if (date) {
        static NSUInteger unitFlags  = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:date];

        self.eventStopTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
        self.eventStopDay.text   = [NSString stringWithFormat:@"%02d", components.day];
        self.eventStopYear.text  = [NSString stringWithFormat:@"%04d", components.year];
        self.eventStopMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    }
}

- (void)animateStartEvent {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.eventStartTime.alpha = 1;
        self.eventStartDay.alpha = 1;
        self.eventStartMonth.alpha = 1;
        self.eventStartYear.alpha = 1;

        self.eventStopTime.alpha = 0.2;
        self.eventStopDay.alpha = 0.2;
        self.eventStopMonth.alpha = 1;
        self.eventStopYear.alpha = 1;
    } completion:nil];
}

- (void)animateStopEvent {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.eventStartTime.alpha = 0.2;
        self.eventStartDay.alpha = 0.2;
        self.eventStartMonth.alpha = 1;
        self.eventStartYear.alpha = 1;

        self.eventStopTime.alpha = 1;
        self.eventStopDay.alpha = 1;
        self.eventStopMonth.alpha = 1;
        self.eventStopYear.alpha = 1;
    } completion:nil];
}

- (void)animateEventTransforming:(EventTimerTransformingEnum)eventTimerTransformingEnum {
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        CGFloat eventStartAlpha, eventStopAlpha, eventTimeAlpha, eventStartMonthYearAlpha, eventStopMonthYearAlpha;
        switch (eventTimerTransformingEnum) {
            case EventTimerStartDateTransformingStart:
                eventStartAlpha = 1;
                eventStartMonthYearAlpha = 1;

                eventStopAlpha = 0.2f;
                eventStopMonthYearAlpha = 0.2f;

                eventTimeAlpha = 0.2f;
                break;
            case EventTimerStartDateTransformingStop:
                eventStartAlpha = [State instance].selectedEvent.isActive ? 1 : 0.2f;
                eventStartMonthYearAlpha = 1;

                eventStopAlpha = [State instance].selectedEvent.isActive ? 0.2f : 1;
                eventStopMonthYearAlpha = 1;

                eventTimeAlpha = 1;
                break;
            case EventTimerStopDateTransformingStart:
                eventStartAlpha = 0.2f;
                eventStartMonthYearAlpha = 0.2f;

                eventStopAlpha = 1;
                eventStopMonthYearAlpha = 1;

                eventTimeAlpha = 0.2f;

                break;
            case EventTimerStopDateTransformingStop:
                eventStartAlpha = [State instance].selectedEvent.isActive ? 1 : 0.2f;
                eventStartMonthYearAlpha = 1;

                eventStopAlpha = [State instance].selectedEvent.isActive ? 0.2f : 1;
                eventStopMonthYearAlpha = 1;

                eventTimeAlpha = 1;
                break;
            default:
                break;
        }

        self.eventStartDay.alpha = eventStartAlpha;
        self.eventStartMonth.alpha = eventStartMonthYearAlpha;
        self.eventStartTime.alpha = eventStartAlpha;
        self.eventStartYear.alpha = eventStartMonthYearAlpha;

        self.eventStopDay.alpha = eventStopAlpha;
        self.eventStopMonth.alpha = eventStopMonthYearAlpha;
        self.eventStopTime.alpha = eventStopAlpha;
        self.eventStopYear.alpha = eventStopMonthYearAlpha;

        self.eventTimeHours.alpha = eventTimeAlpha;
        self.eventTimeMinutes.alpha = eventTimeAlpha;
    } completion:nil];
}

@end