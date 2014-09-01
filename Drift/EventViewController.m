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
#import "EventsGroupedByStartDate.h"
#import <QuartzCore/QuartzCore.h>
#import "State.h"
#import "NSDate+Utilities.h"
#import "UnwindSegueSlideDown.h"
#import "CAAnimation+Blocks.h"

static void *EventViewControllerContext = &EventViewControllerContext;

@interface EventViewController ()

@property (nonatomic) NSArray *shortStandaloneMonthSymbols;
@property (nonatomic) dispatch_queue_t backgroundQueue;

@end

@implementation EventViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.shortStandaloneMonthSymbols = [[NSDateFormatter new] shortStandaloneMonthSymbols];
    self.backgroundQueue = dispatch_queue_create("com.artsoftheinsane.Stray.bgqueue", NULL);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.eventTimerControl addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(startDate))
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:EventViewControllerContext];

    [self.eventTimerControl addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(nowDate))
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:EventViewControllerContext];

    [self.eventTimerControl addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(stopDate))
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:EventViewControllerContext];

    [self.eventTimerControl addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(transforming))
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                context:EventViewControllerContext];

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

    [self.eventTimerControl removeObserver:self
                                forKeyPath:NSStringFromSelector(@selector(startDate))];
    [self.eventTimerControl removeObserver:self
                                forKeyPath:NSStringFromSelector(@selector(nowDate))];
    [self.eventTimerControl removeObserver:self
                                forKeyPath:NSStringFromSelector(@selector(stopDate))];
    [self.eventTimerControl removeObserver:self
                                forKeyPath:NSStringFromSelector(@selector(transforming))];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToTagsFromEvent"]) {
        TagsTableViewController *controller = (TagsTableViewController *)[segue destinationViewController];

        controller.delegate = self;
        controller.event = [State instance].selectedEvent;
    } else if ([segue.identifier isEqualToString:@"segueToEventsFromEvent"]) {
        EventsGroupedByStartDateViewController *controller = (EventsGroupedByStartDateViewController *)[segue destinationViewController];
        controller.delegate = self;
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
        [self animateButton:sender];
        [self performSegueWithIdentifier:@"segueToTagsFromEvent"
                                  sender:self];
    }
}

- (IBAction)toggleEventTouchUpInside:(id)sender forEvent:(UIEvent *)event {
    NSDate *now = [NSDate date];

    if ([[State instance].selectedEvent isActive]) {
        [State instance].selectedEvent.stopDate = now;

        [self.eventTimerControl stop];

        [self.toggleStartStopButton setTitle:@"START"
                                    forState:UIControlStateNormal];
        [self animateStopEvent];
    } else {
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

    [self animateButton:sender];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
}

#pragma mark -
#pragma mark Private methods

- (void)animateButton:(UIButton *)button {
    CGRect       pathFrame = CGRectMake(-CGRectGetMidY(button.bounds), -CGRectGetMidY(button.bounds), button.bounds.size.height, button.bounds.size.height);
    UIBezierPath *path     = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:pathFrame.size.height / 2];

    CGPoint shapePosition = [self.view convertPoint:button.center fromView:button.superview];

    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path        = path.CGPath;
    circleShape.position    = shapePosition;
    circleShape.fillColor   = [UIColor clearColor].CGColor;
    circleShape.opacity     = 0;
    circleShape.strokeColor = button.titleLabel.textColor.CGColor;
    circleShape.lineWidth   = 2;

    [self.view.layer addSublayer:circleShape];

    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue   = [NSValue valueWithCATransform3D:CATransform3DMakeScale(3, 3, 1)];

    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue   = @0;

    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations     = @[scaleAnimation, alphaAnimation];
    animation.duration       = 0.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [animation setCompletion: ^(BOOL finished) {
        [circleShape removeFromSuperlayer];
    }];

    [circleShape addAnimation:animation forKey:nil];
}
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
        static NSUInteger unitFlags  = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:date];

        self.eventStartTime.text  = [NSString stringWithFormat:@"%02ld:%02ld", (long)components.hour, (long)components.minute];
        self.eventStartDay.text   = [NSString stringWithFormat:@"%02ld", (long)components.day];
        self.eventStartYear.text  = [NSString stringWithFormat:@"%04ld", (long)components.year];
        self.eventStartMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:(NSUInteger)(components.month - 1)];
    }
}

- (void)updateEventTimeWithDate:(NSDate *)date {
    if (date && [State instance].selectedEvent.startDate) {
        static NSUInteger unitFlags  = NSCalendarUnitHour | NSCalendarUnitMinute;

        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:[State instance].selectedEvent.startDate
                                                              toDate:date options:0];

        self.eventTimeHours.text   = [NSString stringWithFormat:@"%02ld", (long)components.hour];
        self.eventTimeMinutes.text = [NSString stringWithFormat:@"%02ld", (long)components.minute];
    }
}

- (void)updateStopLabelWithDate:(NSDate *)date {
    if (date) {
        static NSUInteger unitFlags  = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
        NSDateComponents *components = [[NSDate calendar] components:unitFlags
                                                            fromDate:date];

        self.eventStopTime.text  = [NSString stringWithFormat:@"%02ld:%02ld", (long)components.hour, (long)components.minute];
        self.eventStopDay.text   = [NSString stringWithFormat:@"%02ld", (long)components.day];
        self.eventStopYear.text  = [NSString stringWithFormat:@"%04ld", (long)components.year];
        self.eventStopMonth.text = [self.shortStandaloneMonthSymbols objectAtIndex:(NSUInteger)(components.month - 1)];
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
        CGFloat eventStartAlpha = 1, eventStopAlpha = 1, eventTimeAlpha = 1, eventStartMonthYearAlpha = 1, eventStopMonthYearAlpha = 1;
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
            case EventTimerNowDateTransformingStart:
                eventStartAlpha = 0.2f;
                eventStartMonthYearAlpha = 0.2f;

                eventStopAlpha = 1;
                eventStopMonthYearAlpha = 1;

                eventTimeAlpha = 0.2f;

                break;
            case EventTimerNowDateTransformingStop:
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

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == EventViewControllerContext) {
        int changeKindKey = [[change objectForKey:NSKeyValueChangeKindKey] intValue];

        if ([keyPath isEqualToString:NSStringFromSelector(@selector(startDate))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];
                id oldValue = [change objectForKey:NSKeyValueChangeOldKey];

                [State instance].selectedEvent.startDate = newValue;
                [self updateStartLabelWithDate:newValue];

                if (self.eventTimerControl.transforming == EventTimerNotTransforming && oldValue != [NSNull null]) {
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
                }
            }
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(nowDate))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];

                [self updateEventTimeWithDate:newValue];
                [self updateStopLabelWithDate:newValue];
            }
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(stopDate))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];
                id oldValue = [change objectForKey:NSKeyValueChangeOldKey];

                [State instance].selectedEvent.stopDate = newValue;
                [self updateStopLabelWithDate:newValue];

                if (self.eventTimerControl.transforming == EventTimerNotTransforming && oldValue != [NSNull null]) {
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
                }
            }
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(transforming))]) {
            if (changeKindKey == NSKeyValueChangeSetting) {
                id newValue = [change objectForKey:NSKeyValueChangeNewKey];

                EventTimerTransformingEnum isTransforming = [newValue integerValue];
                if (isTransforming != EventTimerNotTransforming) {
                    [self animateEventTransforming:isTransforming];
                }

                if (self.eventTimerControl.transforming == EventTimerNotTransforming) {
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
                }
            }
        }
    }
}

@end