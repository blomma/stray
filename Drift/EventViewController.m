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

@interface EventViewController ()

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) NSCalendar *calendar;

@property (nonatomic) NSDateComponents *previousNowComponents;

@property (nonatomic) State *state;
@property (nonatomic) UIView *infoView;

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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.eventTimerControl paus];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    Event *event = self.state.activeEvent;

    if (event) {
        [self.eventTimerControl startWithEvent:event];

        if ([event isActive]) {
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

    [self.tag setTitle:event.inTag.name forState:UIControlStateNormal];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvent"]) {
        [[segue destinationViewController] setDelegate:self];
        Event *event = [[DataRepository instance] state].activeEvent;

        if ([[segue destinationViewController] respondsToSelector:@selector(event)]) {
            [[segue destinationViewController] setEvent:event];
        }
    } else if ([segue.identifier isEqualToString:@"segueToEventsFromEvent"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

#pragma mark -
#pragma mark TagsTableViewControllerDelegate, EventsGroupedByStartDateViewControllerDelegate

- (void)tagsTableViewControllerDidDimiss:(TagsTableViewController *)tagsTableViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)eventsGroupedByStartDateViewControllerDidDimiss:(EventsGroupedByStartDateViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark InfoViewDelegate

- (void)showInfoViewInView:(UIView *)view {
    if (self.infoView) {
        return;
    }

    CGRect frame = [[UIScreen mainScreen] bounds];

    self.infoView = [[UIView alloc] initWithFrame:frame];


    UIImageView *infoOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Info-Event"]];
    [self.infoView addSubview:infoOverlay];

    // Dismiss button
    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissButton addTarget:self action:@selector(dismissInfoView) forControlEvents:UIControlEventTouchUpInside];
    dismissButton.backgroundColor = [UIColor clearColor];
    dismissButton.frame           = frame;
    [self.infoView addSubview:dismissButton];

    [view addSubview:self.infoView];
}

- (void)dismissInfoView {
    [self.infoView removeFromSuperview];
    self.infoView = nil;
}

#pragma mark -
#pragma mark Public methods

- (IBAction)toggleEvent:(id)sender {
    NSDate *now = [NSDate date];

    Event *event = self.state.activeEvent;

    if ([event isActive]) {
        event.stopDate = now;

        [self.eventTimerControl stop];

        [self.toggleStartStopButton setTitle:@"START" forState:UIControlStateNormal];
        [self animateStopEvent];
    } else {
        [self reset];

        event           = [[DataRepository instance] createEvent];
        event.startDate = now;

        [DataRepository instance].state.activeEvent = event;

        [self.eventTimerControl startWithEvent:event];

        [self.toggleStartStopButton setTitle:@"STOP" forState:UIControlStateNormal];
        [self animateStartEvent];
    }

    [self.tag setTitle:event.inTag.name forState:UIControlStateNormal];
}

- (IBAction)showTags:(id)sender {
    Event *event = self.state.activeEvent;
    if (event) {
        [self performSegueWithIdentifier:@"segueToTagsFromEvent" sender:self];
    }
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
    Event *event = self.state.activeEvent;

    if (date && event.startDate) {
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
    Event *event = [DataRepository instance].state.activeEvent;

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        CGFloat eventStartAlpha, eventStopAlpha, eventTimeAlpha;
        switch (eventTimerTransformingEnum) {
            case EventTimerStartDateTransformingStart:
                eventStartAlpha = 1;
                eventStopAlpha = 0.2f;
                eventTimeAlpha = 0.2f;
                break;
            case EventTimerStartDateTransformingStop:
                eventStartAlpha = event.isActive ? 1:0.2f;
                eventStopAlpha = event.isActive ? 0.2f:1;
                eventTimeAlpha = 1;
                break;
            case EventTimerStopDateTransformingStart:
                eventStartAlpha = 0.2f;
                eventStopAlpha = 1;
                eventTimeAlpha = 0.2f;
                break;
            case EventTimerStopDateTransformingStop:
                eventStartAlpha = event.isActive ? 1:0.2f;
                eventStopAlpha = event.isActive ? 0.2f:1;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    Event *event = [DataRepository instance].state.activeEvent;

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
    }
}

@end