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
#import "DataRepository.h"
#import "TagsTableViewController.h"
#import "Global.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+Retina4.h"
#import "PopoverView.h"

@interface EventViewController ()

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSDateComponents *previousNowComponents;

@property (nonatomic) State *state;
@property (nonatomic) UIView *infoView;

@property (nonatomic, weak) Event *selectedEvent;

@end

@implementation EventViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.state = [DataRepository instance].state;

    [self reset];

    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.calendar                    = [Global instance].calendar;

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

    self.selectedEvent = self.state.activeEvent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.eventTimerControl paus];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.selectedEvent) {
        [self.eventTimerControl startWithEvent:self.selectedEvent];

        if ([self.selectedEvent isActive]) {
            [self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
            [self animateStartEvent];
        } else {
            [self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
            [self animateStopEvent];
        }
    } else {
        [self.eventTimerControl reset];
        [self reset];
    }

    [self.tag setTitle:[self.selectedEvent.inTag.name copy] forState:UIControlStateNormal];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvent"]) {
        [[segue destinationViewController] setDelegate:self];

        if ([[segue destinationViewController] respondsToSelector:@selector(event)]) {
            [[segue destinationViewController] setEvent:self.selectedEvent];
        }
    } else if ([segue.identifier isEqualToString:@"segueToEventsFromEvent"]) {
        [[segue destinationViewController] setDelegate:self];
        [[segue destinationViewController] setSelectedEvent:self.selectedEvent];
    }
}

#pragma mark -
#pragma mark TagsTableViewControllerDelegate, EventsGroupedByStartDateViewControllerDelegate

- (void)tagsTableViewControllerDidDimiss:(TagsTableViewController *)tagsTableViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)eventsGroupedByStartDateViewControllerDidDimiss:(EventsGroupedByStartDateViewController *)viewController {
    self.selectedEvent = viewController.selectedEvent;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark InfoViewDelegate

- (void)showInfoHintView:(UIView *)view {
    [self performSegueWithIdentifier:@"segueToInfoHintViewFromEvent" sender:self];
}

#pragma mark -
#pragma mark Public methods

- (IBAction)showTags:(id)sender {
    if (self.selectedEvent) {
        [self performSegueWithIdentifier:@"segueToTagsFromEvent" sender:self];
    }
}

- (IBAction)toggleEventTouchUpInside:(id)sender forEvent:(UIEvent *)event {
    NSDate *now = [NSDate date];

    if (![self.selectedEvent isEqual:self.state.activeEvent] && self.state.activeEvent.isActive) {
        UIView *button = (UIView *)sender;
        UITouch *touch = [[event touchesForView:button] anyObject];
        CGPoint point  = [touch locationInView:self.view];
        point.y -= 30;

        [PopoverView showPopoverAtPoint:point
                                 inView:self.view
                               withText:@"A timer is already running, stop that one before starting a new"
                               delegate:nil];
        return;
    }

    if ([self.selectedEvent isActive]) {
        self.selectedEvent.stopDate = now;

        [self.eventTimerControl stop];

        [self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
        [self animateStopEvent];
    } else {
        [self reset];

        self.selectedEvent           = [[DataRepository instance] createEvent];
        self.selectedEvent.startDate = now;

        [DataRepository instance].state.activeEvent = self.selectedEvent;

        [self.eventTimerControl startWithEvent:self.selectedEvent];

        [self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
        [self animateStartEvent];
    }

    [self.tag setTitle:self.selectedEvent.inTag.name forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark Private methods

- (void)reset {
    [self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];

    self.eventStartTime.text  = @"";
    self.eventStartDay.text   = @"";
    self.eventStartYear.text  = @"";
    self.eventStartMonth.text = @"";

    self.eventTimeHours.text   = @"00";
    self.eventTimeMinutes.text = @"00";

    self.eventStopTime.text  = @"";
    self.eventStopDay.text   = @"";
    self.eventStopYear.text  = @"";
    self.eventStopMonth.text = @"";
}

- (void)updateStartLabelWithDate:(NSDate *)date {
    if (date) {
        static NSUInteger unitFlags  = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
        NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];

        self.eventStartTime.text  = [NSString stringWithFormat:@"%02d:%02d", components.hour, components.minute];
        self.eventStartDay.text   = [NSString stringWithFormat:@"%02d", components.day];
        self.eventStartYear.text  = [NSString stringWithFormat:@"%04d", components.year];
        self.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:components.month - 1];
    }
}

- (void)updateEventTimeWithDate:(NSDate *)date {
    if (date && self.selectedEvent.startDate) {
        static NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit;

        NSDateComponents *components = [self.calendar components:unitFlags fromDate:self.selectedEvent.startDate toDate:date options:0];

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
        static NSUInteger unitFlags  = NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekdayCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
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
    } completion:nil];
}

- (void)animateStopEvent {
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.eventStartDay.alpha = 0.2;
        self.eventStartMonth.alpha = 1;
        self.eventStartTime.alpha = 0.2;
        self.eventStartYear.alpha = 1;

        self.eventStopDay.alpha = 1;
        self.eventStopMonth.alpha = 1;
        self.eventStopTime.alpha = 1;
        self.eventStopYear.alpha = 1;
    } completion:nil];
}

- (void)animateEventTransforming:(EventTimerTransformingEnum)eventTimerTransformingEnum {
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
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
                eventStartAlpha = self.selectedEvent.isActive ? 1:0.2f;
                eventStartMonthYearAlpha = 1;

                eventStopAlpha = 1;
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
                eventStartAlpha = self.selectedEvent.isActive ? 1:0.2f;
                eventStartMonthYearAlpha = 1;

                eventStopAlpha = self.selectedEvent.isActive ? 0.2f:1;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"startDate"]) {
        NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.selectedEvent.startDate = date;

        [self updateStartLabelWithDate:date];
    } else if ([keyPath isEqualToString:@"nowDate"]) {
        NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];

        [self updateEventTimeWithDate:date];
    } else if ([keyPath isEqualToString:@"stopDate"]) {
        NSDate *date = [change objectForKey:NSKeyValueChangeNewKey];
        self.selectedEvent.stopDate = date;

        [self updateStopLabelWithDate:date];
    } else if ([keyPath isEqualToString:@"isTransforming"]) {
        EventTimerTransformingEnum eventTimerTransformingEnum = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        [self animateEventTransforming:eventTimerTransformingEnum];
    }
}

@end